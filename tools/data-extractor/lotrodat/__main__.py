"""CLI for poking at LOTRO DAT archives.

Usage:
  python3 -m lotrodat info <game_dir>
  python3 -m lotrodat props <game_dir> <did> [--object] [--lang en]
  python3 -m lotrodat raw <game_dir> <did> <out_file>
  python3 -m lotrodat enum <game_dir> <did>
"""
import argparse
import json
import sys

from .facade import DatFacade
from .properties import DBPROPERTIES_OFFSET, StringInfo


def _jsonable(value, facade, lang):
    if isinstance(value, StringInfo):
        text = facade.resolve_string(value, lang)
        if text is not None:
            return text
        return repr(value)
    if isinstance(value, dict):
        return {k: _jsonable(v, facade, lang) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_jsonable(v, facade, lang) for v in value]
    if isinstance(value, float):
        return round(value, 6)
    return value


def main(argv=None):
    ap = argparse.ArgumentParser(prog="lotrodat")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("info", help="archive overview")
    p.add_argument("game_dir")

    p = sub.add_parser("props", help="decode a properties resource")
    p.add_argument("game_dir")
    p.add_argument("did", type=lambda s: int(s, 0))
    p.add_argument("--object", action="store_true",
                   help="did is an object DID: add DBPROPERTIES_OFFSET")
    p.add_argument("--lang", default="en")

    p = sub.add_parser("raw", help="dump a raw payload")
    p.add_argument("game_dir")
    p.add_argument("did", type=lambda s: int(s, 0))
    p.add_argument("out_file")

    p = sub.add_parser("enum", help="decode an enum mapper")
    p.add_argument("game_dir")
    p.add_argument("did", type=lambda s: int(s, 0))

    p = sub.add_parser("scan", help="classify gamelogic entries by WState class")
    p.add_argument("game_dir")
    p.add_argument("--start", type=lambda s: int(s, 0), default=0x70000000)
    p.add_argument("--end", type=lambda s: int(s, 0), default=0x77FFFFFF)
    p.add_argument("--types", help="comma list of class codes: print matching DIDs")

    args = ap.parse_args(argv)
    with DatFacade(args.game_dir) as facade:
        if args.cmd == "info":
            for key, archive in sorted(facade.archives.items()):
                print("%-10s block_size=%d pack_version=%d" % (
                    key, archive.block_size, archive.dat_pack_version))
            print("locales: %s" % ", ".join(sorted(facade.locales)))
            registry = facade.registry
            print("property definitions: %d" % len(registry))
        elif args.cmd == "props":
            did = args.did + (DBPROPERTIES_OFFSET if args.object else 0)
            props = facade.load_properties(did)
            if props is None:
                print("no properties at 0x%08X" % did, file=sys.stderr)
                return 1
            print(json.dumps(_jsonable(props, facade, args.lang),
                             indent=2, ensure_ascii=False, sort_keys=True))
        elif args.cmd == "raw":
            data = facade.load_data(args.did)
            if data is None:
                print("no data at 0x%08X" % args.did, file=sys.stderr)
                return 1
            with open(args.out_file, "wb") as f:
                f.write(data)
            print("wrote %d bytes" % len(data))
        elif args.cmd == "enum":
            mapper = facade.enum_mapper(args.did)
            for code in sorted(mapper.entries):
                print("%6d  %s" % (code, mapper.entries[code]))
        elif args.cmd == "scan":
            wanted = None
            if args.types:
                wanted = {int(t) for t in args.types.split(",")}
            archive = facade.archives["gamelogic"]
            counts = {}
            total = 0
            for entry in archive.iter_entries():
                if not args.start <= entry.file_id <= args.end:
                    continue
                data = archive.load_entry(entry)
                class_code = int.from_bytes(data[4:8], "little")
                total += 1
                counts[class_code] = counts.get(class_code, 0) + 1
                if wanted is not None and class_code in wanted:
                    print("%d %d" % (entry.file_id, class_code))
            if wanted is None:
                for code, n in sorted(counts.items(), key=lambda kv: -kv[1])[:40]:
                    print("%6d  %8d" % (code, n))
                print("total: %d entries in range" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
