# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Property system: definitions registry + properties decoding.

The master property registry lives at DID 0x34000000 in
client_gamelogic.dat. A game object's PropertiesSet lives at
object DID + 0x9000000 (DBPROPERTIES_OFFSET).
"""
from .binio import Reader

DBPROPERTIES_OFFSET = 0x9000000
MASTER_PROPERTY_DID = 0x34000000

# property value type codes
STRING = 1
STRING_TOKEN = 2
WAVE_FORM = 3
TIMESTAMP = 4
TRI_STATE = 5
VECTOR = 6
INSTANCE_ID = 7
ENUM_MAPPER = 8
FLOAT = 9
PROPERTY_ID = 10
STRUCT = 11
ARRAY = 12
STRING_INFO = 13
BITFIELD_64 = 14
INT = 15
COLOR = 16
POSITION = 17
BIT_FIELD32 = 18
LONG64 = 19
DATA_FILE = 20
BOOLEAN = 21
BIT_FIELD = 22


class PropertyDef:
    __slots__ = ("pid", "name", "type", "data")

    def __init__(self, pid, name):
        self.pid = pid
        self.name = name
        self.type = None
        self.data = 0  # enum DID for ENUM_MAPPER/BIT_FIELD* types

    def __repr__(self):
        return "PropertyDef(%d, %r, type=%s)" % (self.pid, self.name, self.type)


class StringInfo:
    """Unrendered string reference: either a literal or (table DID, token)."""

    __slots__ = ("literal", "table_did", "token", "variables")

    def __init__(self, literal=None, table_did=0, token=0):
        self.literal = literal
        self.table_did = table_did
        self.token = token
        self.variables = None  # optional {name_hash_or_None: value}

    def __repr__(self):
        if self.literal is not None:
            return "StringInfo(literal=%r)" % self.literal
        return "StringInfo(table=0x%08X, token=0x%08X)" % (
            self.table_did, self.token)


def load_registry(buf):
    """Decode the master property file into {pid: PropertyDef}."""
    r = Reader(buf)
    did = r.u32()
    if did != MASTER_PROPERTY_DID:
        raise ValueError("master property DID mismatch: 0x%08X" % did)
    r.skip(8)
    registry = {}
    for _ in range(r.tsize()):
        pid = r.u32()
        registry[pid] = PropertyDef(pid, r.pascal_string())
    r.skip(2)
    for _ in range(r.tsize()):
        pid = r.u32()
        _read_property_definition(r, pid, registry)
    if r.remaining() >= 4:
        raise ValueError("master property: %d trailing bytes" % r.remaining())
    return registry


def _read_property_definition(r, expected_pid, registry):
    definition = registry[expected_pid]
    pid = r.u32()
    if pid != expected_pid:
        raise ValueError("PID mismatch: %d != %d" % (pid, expected_pid))
    type_code = r.u32()
    if not 1 <= type_code <= 22:
        raise ValueError("bad property type %d for PID %d" % (type_code, pid))
    definition.type = type_code
    r.skip(8)  # group, provider
    definition.data = r.u32()
    r.skip(4)  # ePatchFlags
    flags = (r.u32() >> 8) & 0xFF
    for bit in (8, 0x10, 0x20):  # default, min, max values
        if flags & bit:
            if type_code not in (PROPERTY_ID, STRUCT, ARRAY):
                _read_value(r, type_code, None)
    r.skip(4 + 4 + 1)  # predictionTimeout f32, 4 type bytes, 1 pad
    n_children = r.vle()
    for _ in range(n_children):
        c1 = r.u32()
        c2 = r.u32()
        if c1 != c2:
            raise ValueError("child PID mismatch: %d != %d" % (c1, c2))
    n_required = r.u32()
    r.skip(4 * n_required)
    zero = r.u32()
    if zero != 0:
        raise ValueError("property def trailer not zero: %d" % zero)


class PropertiesDecoder:
    """Decodes PropertiesSet resources using a property registry."""

    def __init__(self, registry):
        self.registry = registry

    def decode_resource(self, buf):
        """buf is a DID+0x9000000 payload; returns {name: value}."""
        r = Reader(buf)
        r.u32()  # own DID
        props = {}
        self._decode_into(r, props)
        return props

    def _decode_into(self, r, props):
        for _ in range(r.tsize()):
            item = self._decode_property(r, double_pid=True)
            if item is not None:
                props[item[0]] = item[1]

    def _decode_property(self, r, double_pid):
        pid = r.u32()
        if pid == 0:
            return None
        if double_pid:
            pid2 = r.u32()
            if pid2 != pid:
                raise ValueError("property ID mismatch: %d != %d" % (pid, pid2))
        definition = self.registry.get(pid)
        if definition is None:
            raise ValueError("unknown property ID: %d" % pid)
        return (definition.name, self._decode_value(r, definition))

    def _decode_value(self, r, definition):
        t = definition.type
        if t == ARRAY:
            count = r.u32()
            out = []
            for _ in range(count):
                item = self._decode_property(r, double_pid=False)
                out.append(None if item is None else item[1])
            return out
        if t == STRUCT:
            r.skip(1)
            count = r.u8()
            sub = {}
            for _ in range(count):
                item = self._decode_property(r, double_pid=True)
                if item is not None:
                    sub[item[0]] = item[1]
            return sub
        return _read_value(r, t, definition)


def _read_value(r, t, definition):
    """Scalar value readers, one per property type."""
    if t == STRING:
        return r.pascal_string()
    if t in (STRING_TOKEN, ENUM_MAPPER, PROPERTY_ID, BIT_FIELD32, DATA_FILE):
        return r.u32()
    if t == INT:
        return r.i32()
    if t == WAVE_FORM:
        return _read_wave_form(r)
    if t == TIMESTAMP:
        return r.f64()
    if t in (TRI_STATE, BOOLEAN):
        return r.u8()
    if t == VECTOR:
        return (r.f32(), r.f32(), r.f32())
    if t == INSTANCE_ID:
        return r.u64()
    if t == FLOAT:
        return r.f32()
    if t == STRING_INFO:
        return read_string_info(r)
    if t in (BITFIELD_64, LONG64):
        return r.u64()
    if t == COLOR:
        return (r.u8(), r.u8(), r.u8(), r.u8())
    if t == POSITION:
        return _read_position(r)
    if t == BIT_FIELD:
        bit_count = r.vle()
        byte_count = (bit_count + 7) // 8
        return int.from_bytes(r.read(byte_count), "little")
    if t in (STRUCT, ARRAY, PROPERTY_ID):
        raise ValueError("container type %d has no scalar value" % t)
    raise ValueError("unmanaged property type: %d" % t)


def _read_wave_form(r):
    wtype = r.u32()
    if wtype == 10:
        values = tuple(r.f32() for _ in range(10))
        r.f32()
        r.boolean()
        pair_count = r.u32()
        for _ in range(pair_count * 2):
            r.f32()
        return (wtype, values)
    # LIVE version
    if wtype == 1:
        return (wtype, r.f32())
    if wtype > 1:
        return (wtype, tuple(r.f32() for _ in range(10)))
    return (wtype, None)


def _read_position(r):
    flags = r.u8()
    if flags == 0:
        return None
    pos = {}
    if flags & 1:
        pos["region"] = r.u8()
    if flags & 2:
        pos["block"] = (r.u8(), r.u8())
    if flags & 4:
        pos["instance"] = r.u16()
    if flags & 8:
        pos["cell"] = r.u16()
    if flags & 0x10:
        pos["position"] = (r.f32(), r.f32(), r.f32())
    if flags & 0x20:
        r.skip(16)  # orientation quaternion, unused
    return pos


def read_string_info(r):
    """String reference: literal, or (table DID, token) + variables."""
    if r.boolean():
        info = StringInfo(literal=r.utf16_string())
    else:
        token = r.u32()
        data_id = r.u32()
        info = StringInfo(table_did=data_id, token=token)
    if r.boolean():
        r.pascal_string()
        r.pascal_string()
        r.pascal_string()
        for _ in range(r.vle()):
            data_type = r.u8()
            if data_type not in (1, 2, 4):
                raise ValueError("string info replacement type %d" % data_type)
            var_hash = r.u32()
            if data_type != 1:
                is1 = r.u8()
                if is1 != 1:
                    raise ValueError("string info is1=%d" % is1)
            if data_type == 4:
                value = r.vle()
            elif data_type == 1:
                value = read_string_info(r)
            else:
                value = r.f32()
            if info.variables is None:
                info.variables = {}
            info.variables[var_hash] = value
    else:
        r1 = r.u8()
        r2 = r.u8()
        if r1 != 1 or r2 != 0:
            raise ValueError("string info remainder: %d, %d" % (r1, r2))
    return info
