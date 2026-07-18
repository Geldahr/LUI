# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Pure-Python reader for LOTRO client .dat archives. Stdlib only."""
from .archive import DatArchive
from .facade import DatFacade
from .properties import DBPROPERTIES_OFFSET, StringInfo
