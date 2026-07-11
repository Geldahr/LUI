"""High-level access to a LOTRO game install's DAT archives, limited
to the archives needed for data extraction: gamelogic, general and the
per-language local archives.
"""
import os

from .archive import DatArchive
from .properties import (DBPROPERTIES_OFFSET, MASTER_PROPERTY_DID,
                         PropertiesDecoder, StringInfo, load_registry)
from .binio import Reader
from .strings import (load_enum_mapper, load_enum_raw, load_string_table,
                      render_entry)

# client_local_*.dat name -> our language code
LOCALE_FILES = {
    "English": "en",
    "DE": "de",
    "FR": "fr",
    "RU": "ru",
}


def _did_archives(did):
    """Which archive(s) hold a DID range (data-extraction subset)."""
    if 0x07000000 <= did <= 0x07FFFFFF:
        return ("gamelogic",)
    if did == MASTER_PROPERTY_DID:
        return ("gamelogic",)
    if 0x25000000 <= did <= 0x26FFFFFF:
        return ("local",)
    if 0x22000000 <= did <= 0x22FFFFFF:
        return ("general", "local")
    if 0x47000000 <= did <= 0x47FFFFFF or 0x56000000 <= did <= 0x56FFFFFF:
        return ("gamelogic",)
    if 0x70000000 <= did <= 0x77FFFFFF:
        return ("gamelogic",)
    if 0x78000000 <= did <= 0x7FFFFFFF:
        return ("gamelogic", "local")
    if (0x01000000 <= did <= 0x01FFFFFF or 0x04000000 <= did <= 0x04FFFFFF
            or 0x0E000004 <= did <= 0x0E4FFFFF or 0x0F000000 <= did <= 0x0FFFFFFF
            or 0x18000000 <= did <= 0x18FFFFFF or 0x1F000000 <= did <= 0x20FFFFFF
            or 0x23000000 <= did <= 0x23FFFFFF or 0x28000000 <= did <= 0x28FFFFFF
            or 0x2A000000 <= did <= 0x2BFFFFFF or 0x30000000 <= did <= 0x31FFFFFF
            or 0x40000000 <= did <= 0x40FFFFFF):
        return ("general",)
    return None


class DatFacade:
    """Opens gamelogic/general plus every available local archive."""

    def __init__(self, game_dir, default_locale="en"):
        self.game_dir = game_dir
        self.archives = {}
        for key in ("gamelogic", "general"):
            path = os.path.join(game_dir, "client_%s.dat" % key)
            self.archives[key] = DatArchive(path)
        self.locales = {}
        for suffix, lang in LOCALE_FILES.items():
            path = os.path.join(game_dir, "client_local_%s.dat" % suffix)
            if os.path.exists(path):
                self.locales[lang] = DatArchive(path)
        if default_locale not in self.locales:
            raise ValueError("locale %r not available (have: %s)" % (
                default_locale, sorted(self.locales)))
        self.default_locale = default_locale
        self._registry = None
        self._decoder = None
        self._string_tables = {}  # (lang, did) -> StringTable
        self._enums = {}          # did -> EnumMapper
        self._raw_enums = {}      # did -> RawEnum
        self._defs_by_name = None
        self._weenies = None      # name -> DID

    def close(self):
        for archive in self.archives.values():
            archive.close()
        for archive in self.locales.values():
            archive.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    # --- raw access ------------------------------------------------------

    def load_data(self, did, lang=None):
        """Load a payload by DID; returns bytes or None."""
        keys = _did_archives(did)
        if keys is None:
            raise ValueError("no archive mapping for DID 0x%08X" % did)
        for key in keys:
            if key == "local":
                archive = self.locales[lang or self.default_locale]
            else:
                archive = self.archives[key]
            data = archive.load(did)
            if data is not None:
                return data
        return None

    # --- properties ------------------------------------------------------

    @property
    def registry(self):
        if self._registry is None:
            self._registry = load_registry(
                self.archives["gamelogic"].load(MASTER_PROPERTY_DID))
        return self._registry

    def load_properties(self, did):
        """PropertiesSet of a DB properties resource; None if absent.

        Pass object DID + DBPROPERTIES_OFFSET (like the Java facade).
        """
        data = self.load_data(did)
        if data is None:
            return None
        if self._decoder is None:
            self._decoder = PropertiesDecoder(self.registry)
        return self._decoder.decode_resource(data)

    def load_object_properties(self, object_did):
        return self.load_properties(object_did + DBPROPERTIES_OFFSET)

    # --- strings -----------------------------------------------------------

    def string_table(self, did, lang=None):
        lang = lang or self.default_locale
        key = (lang, did)
        table = self._string_tables.get(key)
        if table is None:
            data = self.locales[lang].load(did)
            if data is None:
                return None
            table = load_string_table(data)
            self._string_tables[key] = table
        return table

    def resolve_string(self, info, lang=None, raw=False):
        """Render a StringInfo to text for one language; None if absent."""
        if not isinstance(info, StringInfo):
            return info  # already a plain value
        if info.literal is not None:
            return info.literal
        if info.table_did == 0:
            return None
        table = self.string_table(info.table_did, lang)
        if table is None:
            return None
        entry = table.entries.get(info.token)
        if entry is None:
            return None
        text = render_entry(entry[0], entry[1])
        return text

    # --- enums --------------------------------------------------------------

    def enum_mapper(self, did):
        mapper = self._enums.get(did)
        if mapper is None:
            data = self.load_data(did)
            if data is None:
                raise ValueError("enum 0x%08X not found" % did)
            mapper = load_enum_mapper(data, self.resolve_string)
            self._enums[did] = mapper
        return mapper

    def enum_names(self, did, lang):
        """{code: label} for one language (localized where possible)."""
        raw = self._raw_enums.get(did)
        if raw is None:
            data = self.load_data(did)
            if data is None:
                raise ValueError("enum 0x%08X not found" % did)
            raw = load_enum_raw(data)
            self._raw_enums[did] = raw
        names = dict(raw.entries)
        for code, info in raw.string_infos.items():
            label = self.resolve_string(info, lang)
            if label is not None:
                names[code] = label
        return names

    def property_def(self, name):
        """Property definition by name (for enum DIDs etc.)."""
        if self._defs_by_name is None:
            self._defs_by_name = {}
            for definition in self.registry.values():
                self._defs_by_name[definition.name] = definition
        return self._defs_by_name[name]

    # --- weenie content directory ---------------------------------------

    def _data_id_map(self, did):
        """Decode a data-id directory map resource: {label: DID}."""
        data = self.load_data(did)
        r = Reader(data)
        r.u32()  # own DID
        ids, labels = {}, {}
        while r.remaining() > 0:
            count = r.tsize()
            for _ in range(count):
                k = r.u32()
                ids[k] = r.u32()
            count2 = r.tsize()
            if count2 != count:
                raise ValueError("data id map: %d != %d" % (count, count2))
            for _ in range(count):
                k = r.u32()
                labels[k] = r.ascii_string()
        return {labels[k]: mapped for k, mapped in ids.items() if k in labels}

    def weenie_props(self, name):
        """PropertiesSet of a named WeenieContent entry (e.g.
        "CooldownControl"): root map at 0x28000000 -> WEENIECONTENT
        sub-map -> named object."""
        if self._weenies is None:
            root = self._data_id_map(0x28000000)
            self._weenies = self._data_id_map(root["WEENIECONTENT"])
        return self.load_object_properties(self._weenies[name])
