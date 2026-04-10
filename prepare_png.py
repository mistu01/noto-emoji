#!/usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image


def _parse_pair(values):
    if len(values) != 2:
        raise ValueError("expected exactly two integers")
    return int(values[0]), int(values[1])


def main():
    parser = argparse.ArgumentParser(
        description="Resize a PNG to fit within a box and center it on a transparent canvas."
    )
    parser.add_argument("src")
    parser.add_argument("dst")
    parser.add_argument("--fit", nargs=2, metavar=("WIDTH", "HEIGHT"), required=True)
    parser.add_argument("--canvas", nargs=2, metavar=("WIDTH", "HEIGHT"), required=True)
    args = parser.parse_args()

    fit_w, fit_h = _parse_pair(args.fit)
    canvas_w, canvas_h = _parse_pair(args.canvas)

    src = Path(args.src)
    dst = Path(args.dst)
    dst.parent.mkdir(parents=True, exist_ok=True)

    with Image.open(src) as image:
        image = image.convert("RGBA")
        image.thumbnail((fit_w, fit_h), Image.Resampling.LANCZOS)

        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        offset = (
            (canvas_w - image.width) // 2,
            (canvas_h - image.height) // 2,
        )
        canvas.alpha_composite(image, dest=offset)
        canvas.save(dst, format="PNG")


if __name__ == "__main__":
    main()
