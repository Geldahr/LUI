# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Binary reader primitives for LOTRO DAT data (little-endian)."""
import struct


class Reader:
    """Sequential reader over a bytes-like buffer."""

    __slots__ = ("buf", "pos")

    def __init__(self, buf, pos=0):
        self.buf = buf
        self.pos = pos

    def remaining(self):
        return len(self.buf) - self.pos

    def skip(self, n):
        self.pos += n

    def read(self, n):
        b = self.buf[self.pos:self.pos + n]
        if len(b) != n:
            raise EOFError("wanted %d bytes, got %d (pos=%d)" % (n, len(b), self.pos))
        self.pos += n
        return b

    def u8(self):
        v = self.buf[self.pos]
        self.pos += 1
        return v

    def u16(self):
        (v,) = struct.unpack_from("<H", self.buf, self.pos)
        self.pos += 2
        return v

    def u32(self):
        (v,) = struct.unpack_from("<I", self.buf, self.pos)
        self.pos += 4
        return v

    def i32(self):
        (v,) = struct.unpack_from("<i", self.buf, self.pos)
        self.pos += 4
        return v

    def u64(self):
        (v,) = struct.unpack_from("<Q", self.buf, self.pos)
        self.pos += 8
        return v

    def f32(self):
        (v,) = struct.unpack_from("<f", self.buf, self.pos)
        self.pos += 4
        return v

    def f64(self):
        (v,) = struct.unpack_from("<d", self.buf, self.pos)
        self.pos += 8
        return v

    def boolean(self):
        v = self.u8()
        if v > 1:
            raise ValueError("invalid boolean value: %d (pos=%d)" % (v, self.pos - 1))
        return v == 1

    def vle(self):
        """Variable-length integer."""
        a = self.u8()
        if a == 224:
            return self.u32()
        if (a & 0x80) == 0:
            return a
        b = self.u8()
        if (a & 0x40) == 0:
            return b | (a & 0x7F) << 8
        c = self.u16()
        return (a & 0x3F) << 24 | b << 16 | c

    def tsize(self):
        """Count prefixed by one ignored byte."""
        self.skip(1)
        return self.vle()

    def pascal_string(self):
        """VLE-length ISO-8859-1 string."""
        length = self.vle()
        return self.read(length).decode("latin-1")

    def ascii_string(self):
        """u8-length ASCII string."""
        length = self.u8()
        return self.read(length).decode("ascii")

    def utf16_string(self):
        """VLE char count, then UTF-16LE payload."""
        length = self.vle()
        if length > 20000:
            raise ValueError("bad utf16 string length: %d" % length)
        return self.read(length * 2).decode("utf-16-le")
