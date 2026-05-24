"""Sanity check image sizes and svg viewboxes."""
import argparse
from PIL import Image
from pathlib import Path
from lxml import etree
import sys

PNG_SIZE_OVERRIDES = {
    # Apple source artwork in png/128 is authored at 160x160 and scaled during
    # the build to fit the font's 128px body box.
    "128": (128, 128),
}


def _check_image(base_dir, image_dir):
	assert image_dir.is_dir()
	expected_size = PNG_SIZE_OVERRIDES.get(
		image_dir.name, (int(image_dir.name), int(image_dir.name))
	)

	num_bad = 0
	num_good = 0
	for image_file in image_dir.iterdir():
		with Image.open(image_file) as image:
			actual_size = image.size
		if expected_size != actual_size:
			print(f"bad_dim {image_file.relative_to(base_dir)} actual {actual_size} expected {expected_size}")
			num_bad += 1
		else:
			num_good += 1
	return num_bad, num_good

def _check_svg(base_dir, svg_dir):
	expected_viewbox = (0.0, 0.0, 128.0, 128.0)
	num_bad = 0
	num_good = 0
	for svg_file in svg_dir.iterdir():
		if not svg_file.name.startswith("emoji_u"):
			continue
		assert svg_file.is_file()
		with open(svg_file) as f:
			actual_viewbox = etree.parse(f).getroot().attrib["viewBox"]
		actual_viewbox = tuple(float(s) for s in actual_viewbox.split(" "))
		if expected_viewbox != actual_viewbox:
			print(f"bad_dim {svg_file.relative_to(base_dir)} actual {actual_viewbox} expected {expected_viewbox}")
			num_bad += 1
		else:
			num_good += 1
	return num_bad, num_good

def _parse_args():
	parser = argparse.ArgumentParser()
	parser.add_argument(
		"--png-dir",
		action="append",
		dest="png_dirs",
		help="Specific PNG size directories to validate, relative to the repo root.",
	)
	parser.add_argument(
		"--skip-svg",
		action="store_true",
		help="Skip validating SVG viewBoxes.",
	)
	return parser.parse_args()


def main():
	args = _parse_args()
	base_dir = Path(__file__).parent
	image_dir = base_dir / "png"
	svg_dir = base_dir / "svg"

	assert image_dir.is_dir()
	if not args.skip_svg:
		assert svg_dir.is_dir()

	if args.png_dirs:
		size_dirs = [base_dir / png_dir for png_dir in args.png_dirs]
	else:
		size_dirs = list(image_dir.iterdir())

	num_bad_total = 0
	for size_dir in size_dirs:
		num_bad, num_good = _check_image(base_dir, size_dir)
		print(f"{num_bad}/{num_bad+num_good} issues with {size_dir}")
		num_bad_total += num_bad
	if not args.skip_svg:
		num_bad, num_good = _check_svg(base_dir, svg_dir)
		print(f"{num_bad}/{num_bad+num_good} issues with {svg_dir}")
		num_bad_total += num_bad
	sys.exit(num_bad_total)

if __name__ == "__main__":
   main()
