#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Build LUI's white, tintable UI icons (64x64 32-bit TGA).

Reads tools/icons/icons.txt. Lucide SVGs come from the tools/icons/lucide
submodule. Requires: resvg-py, Pillow.

Every output pixel is white; the shape lives only in the alpha channel, so
the game can tint the icon (Multiply) without dark edge fringes.
"""
import io
import os
import re
import sys

import resvg_py
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
LUCIDE_DIR = os.path.join(HERE, "lucide", "icons")
SOURCES_DIR = os.path.join(HERE, "sources")
OUT_DIR = os.path.join(REPO, "assets", "ui", "icons")
LIST_FILE = os.path.join(HERE, "icons.txt")

SIZE = 64
SUPERSAMPLE = 4
WHITE = (255, 255, 255)
WEIGHTS = (("thin", 2.0), ("bold", 2.5))


def _white_from_alpha(alpha):
    out = Image.new("RGBA", (SIZE, SIZE), WHITE + (0,))
    out.putalpha(alpha)
    return out


def _save(image, name):
    path = os.path.join(OUT_DIR, name)
    # same header as the existing assets: uncompressed, top-left origin
    image.save(path, format="TGA", compression=None, orientation=1)
    return path


def render_lucide(icon, stroke_width, filled, zoom):
    svg = open(os.path.join(LUCIDE_DIR, icon + ".svg"), encoding="utf-8").read()
    svg = svg.replace('stroke="currentColor"', 'stroke="#FFFFFF"')
    # zoom crops the 24-unit canvas around its centre so small glyphs
    # (chevrons) fill their slot; the stroke shrinks by the same factor so
    # the rendered line weight matches the other icons
    svg = re.sub(r'stroke-width="[^"]*"', 'stroke-width="%s"' % (stroke_width / zoom), svg, count=1)
    if zoom != 1:
        side = 24.0 / zoom
        origin = (24.0 - side) / 2
        svg = svg.replace('viewBox="0 0 24 24"', 'viewBox="%s %s %s %s"' % (origin, origin, side, side), 1)
    if filled:
        svg = svg.replace('fill="none"', 'fill="#FFFFFF"', 1)
    png = resvg_py.svg_to_bytes(svg_string=svg, width=SIZE * SUPERSAMPLE, height=SIZE * SUPERSAMPLE)
    alpha = Image.open(io.BytesIO(bytes(png))).convert("RGBA").getchannel("A")
    return _white_from_alpha(alpha.resize((SIZE, SIZE), Image.LANCZOS))


def convert_own(source):
    image = Image.open(os.path.join(SOURCES_DIR, source)).convert("RGBA")
    if image.size != (SIZE, SIZE):
        raise SystemExit("%s: expected %dx%d, got %r" % (source, SIZE, SIZE, image.size))
    return _white_from_alpha(image.getchannel("A"))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    written = []
    for line_no, raw in enumerate(open(LIST_FILE, encoding="utf-8"), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        kind = parts[0]
        if kind == "lucide":
            out_name, icon = parts[1], parts[2]
            options = parts[3:]
            filled = "filled" in options
            zoom = 1.0
            for option in options:
                if option.startswith("zoom="):
                    zoom = float(option[len("zoom="):])
            for weight, stroke in WEIGHTS:
                written.append(_save(render_lucide(icon, stroke, filled, zoom),
                                     "%s_%s_64.tga" % (out_name, weight)))
        elif kind == "own":
            out_name, source = parts[1], parts[2]
            written.append(_save(convert_own(source), "%s_64.tga" % out_name))
        else:
            raise SystemExit("%s:%d: unknown kind %r" % (LIST_FILE, line_no, kind))
    for path in written:
        print(os.path.relpath(path, REPO))
    print("%d icons" % len(written))


if __name__ == "__main__":
    sys.exit(main())
