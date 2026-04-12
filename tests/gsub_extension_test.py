import importlib.util
from pathlib import Path
import sys
from types import SimpleNamespace

REPO_ROOT = Path(__file__).resolve().parents[1]
EMOJI_BUILDER_PATH = REPO_ROOT / "third_party" / "color_emoji" / "emoji_builder.py"
MAP_PUA_EMOJI_PATH = REPO_ROOT / "map_pua_emoji.py"
COLOR_EMOJI_DIR = EMOJI_BUILDER_PATH.parent


def _load_module(name, path):
    for candidate in (str(REPO_ROOT), str(COLOR_EMOJI_DIR)):
        if candidate not in sys.path:
            sys.path.insert(0, candidate)
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _fake_font(subtable):
    lookup = SimpleNamespace(SubTable=[subtable])
    gsub = SimpleNamespace(
        table=SimpleNamespace(LookupList=SimpleNamespace(Lookup=[lookup]))
    )
    return {"GSUB": gsub}


def _extension_ligature_subtable(first_glyph, ligature_glyph, components):
    ligature = SimpleNamespace(Component=components, LigGlyph=ligature_glyph)
    ligature_subtable = SimpleNamespace(ligatures={first_glyph: [ligature]})
    return SimpleNamespace(ExtSubTable=ligature_subtable)


def test_emoji_builder_handles_extension_ligatures():
    emoji_builder = _load_module("emoji_builder", EMOJI_BUILDER_PATH)
    font = _fake_font(
        _extension_ligature_subtable(
            "glyph_one", "glyph_keycap", ["glyph_combining_keycap"]
        )
    )
    glyph_name = emoji_builder.get_glyph_name_from_gsub(
        "1\u20e3", font, {ord("1"): "glyph_one", 0x20E3: "glyph_combining_keycap"}
    )
    assert glyph_name == "glyph_keycap"


def test_map_pua_handles_extension_ligatures(monkeypatch):
    map_pua_emoji = _load_module("map_pua_emoji", MAP_PUA_EMOJI_PATH)
    font = _fake_font(
        _extension_ligature_subtable(
            "glyph_one", "glyph_keycap", ["glyph_combining_keycap"]
        )
    )
    monkeypatch.setattr(
        map_pua_emoji.font_data,
        "get_cmap",
        lambda _: {ord("1"): "glyph_one", 0x20E3: "glyph_combining_keycap"},
    )
    glyph_name = map_pua_emoji.get_glyph_name_from_gsub([ord("1"), 0x20E3], font)
    assert glyph_name == "glyph_keycap"
