"""LOTRO .dat archive container reader.

A .dat file is a block filesystem with a B-tree directory keyed by
file ID (DID). File payloads may be zlib-compressed (entry flag
bit 0), with a 4-byte uncompressed-size prefix before the zlib stream.
"""
import struct
import zlib

MAGIC = 21570
DIRECTORY_RAW_SIZE = 2452
ROOT_DIR_BLOCK_SIZE = 2460
MAX_ENTRIES = 61
SUPERBLOCK_OFFSET = 320


class FileEntry:
    __slots__ = ("file_id", "offset", "size", "timestamp", "version",
                 "block_size", "flags", "policy")

    def __init__(self, file_id, offset, size, timestamp, version,
                 block_size, flags, policy):
        self.file_id = file_id
        self.offset = offset
        self.size = size
        self.timestamp = timestamp
        self.version = version
        self.block_size = block_size
        self.flags = flags
        self.policy = policy

    @property
    def compressed(self):
        return (self.flags & 1) != 0

    def __repr__(self):
        return "FileEntry(0x%08X, size=%d, flags=%d)" % (
            self.file_id, self.size, self.flags)


class _DirNode:
    __slots__ = ("children", "files")

    def __init__(self, children, files):
        self.children = children  # list of (offset, block_size)
        self.files = files        # list of FileEntry, sorted by file_id


class DatArchive:
    """One client_*.dat file."""

    def __init__(self, path):
        self.path = path
        self._f = open(path, "rb")
        self._nodes = {}  # offset -> _DirNode
        self._read_superblock()

    def close(self):
        self._f.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def _read_at(self, offset, size):
        self._f.seek(offset)
        data = self._f.read(size)
        if len(data) != size:
            raise EOFError("%s: short read at %d (%d != %d)" % (
                self.path, offset, len(data), size))
        return data

    def _read_superblock(self):
        buf = self._read_at(SUPERBLOCK_OFFSET, 104)
        magic, self.block_size = struct.unpack_from("<II", buf, 0)
        if magic != MAGIC:
            raise ValueError("%s: bad magic %d (expected %d)" % (
                self.path, magic, MAGIC))
        (self.root_offset,) = struct.unpack_from("<I", buf, 32)
        (self.dat_pack_version,) = struct.unpack_from("<I", buf, 52)

    # --- block reading -------------------------------------------------

    def _read_block(self, offset, block_size, size):
        if self.dat_pack_version == 111:
            return self._read_old_block(offset, block_size, size)
        header = self._read_at(offset, 8)
        num_extra, legacy = struct.unpack("<II", header)
        if legacy != 0:
            return self._read_old_block(offset, block_size, size)
        first_chunk_size = block_size - 8 - num_extra * 8
        if first_chunk_size > size:
            first_chunk_size = size
        out = bytearray(size)
        pos = offset + 8
        out[0:first_chunk_size] = self._read_at(pos, first_chunk_size)
        pos += first_chunk_size
        index = first_chunk_size
        if num_extra:
            table = self._read_at(pos, num_extra * 8)
            for i in range(num_extra):
                bsize, boffset = struct.unpack_from("<II", table, i * 8)
                to_read = min(bsize, size - index)
                out[index:index + to_read] = self._read_at(boffset, to_read)
                index += to_read
        return bytes(out)

    def _read_old_block(self, offset, block_size, size):
        # Chained blocks, filled from the end of the output buffer backwards.
        out = bytearray(size)
        bytes_read = 0
        pos = size
        cur_offset = offset
        cur_block_size = block_size
        for _ in range(1000):
            header = self._read_at(cur_offset, 8)
            next_block_size, next_offset = struct.unpack("<II", header)
            cur_offset += 8
            if next_block_size == 0:
                to_read = size - bytes_read
                if to_read > 0:
                    out[0:to_read] = self._read_at(cur_offset, to_read)
                return bytes(out)
            to_read = cur_block_size - 8
            pos -= to_read
            out[pos:pos + to_read] = self._read_at(cur_offset, to_read)
            bytes_read += to_read
            cur_offset = next_offset
            cur_block_size = next_block_size
        raise ValueError("%s: too many steps in old block chain at %d" % (
            self.path, offset))

    # --- directory B-tree ----------------------------------------------

    def _node(self, offset, block_size):
        node = self._nodes.get(offset)
        if node is not None:
            return node
        buf = self._read_block(offset, block_size, DIRECTORY_RAW_SIZE)
        (files_count,) = struct.unpack_from("<I", buf, 496)
        if files_count > MAX_ENTRIES:
            raise ValueError("%s: directory node at %d has %d entries" % (
                self.path, offset, files_count))
        children = []
        for i in range(files_count + 1):
            bsize, boffset = struct.unpack_from("<II", buf, i * 8)
            if bsize == 0:
                continue
            children.append((boffset, bsize))
        files = []
        for i in range(files_count):
            base = 500 + i * 32
            flags, policy, file_id, foffset, fsize, ts, ver, bsize = \
                struct.unpack_from("<HHIIIIII", buf, base)
            files.append(FileEntry(file_id, foffset, fsize, ts, ver,
                                   bsize, flags, policy))
        node = _DirNode(children, files)
        self._nodes[offset] = node
        return node

    def get_entry(self, file_id):
        """B-tree lookup; returns FileEntry or None."""
        offset, block_size = self.root_offset, ROOT_DIR_BLOCK_SIZE
        while True:
            node = self._node(offset, block_size)
            files = node.files
            lo, hi = 0, len(files) - 1
            while lo <= hi:
                mid = (lo + hi) // 2
                cur = files[mid].file_id
                if cur < file_id:
                    lo = mid + 1
                elif cur > file_id:
                    hi = mid - 1
                else:
                    return files[mid]
            if not node.children:
                return None
            offset, block_size = node.children[lo]

    def iter_entries(self):
        """Depth-first walk of every file entry in the archive."""
        stack = [(self.root_offset, ROOT_DIR_BLOCK_SIZE)]
        while stack:
            offset, block_size = stack.pop()
            node = self._node(offset, block_size)
            for entry in node.files:
                yield entry
            stack.extend(node.children)

    # --- payloads -------------------------------------------------------

    def load_entry(self, entry):
        data = self._read_block(entry.offset, entry.block_size, entry.size)
        if entry.compressed:
            uncompressed_size = struct.unpack_from("<I", data, 0)[0]
            data = zlib.decompress(data[4:])
            if len(data) != uncompressed_size:
                raise ValueError(
                    "0x%08X: uncompressed %d bytes, header says %d" % (
                        entry.file_id, len(data), uncompressed_size))
        return data

    def load(self, file_id):
        """Load a file payload by ID; returns bytes or None if absent."""
        entry = self.get_entry(file_id)
        if entry is None:
            return None
        return self.load_entry(entry)
