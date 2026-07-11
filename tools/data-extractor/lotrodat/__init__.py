"""Pure-Python reader for LOTRO client .dat archives. Stdlib only."""
from .archive import DatArchive
from .facade import DatFacade
from .properties import DBPROPERTIES_OFFSET, StringInfo
