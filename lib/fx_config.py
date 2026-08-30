"""Shared Neon FX defaults, presets, and config helpers."""

from __future__ import annotations

import json
import os
import re

STATE_DIR = os.path.expanduser("~/.local/state/omarchy/neonfx")
TOGGLE_DIR = os.path.expanduser("~/.local/state/omarchy/toggles/neonfx")
CONFIG_FILE = os.path.join(STATE_DIR, "fx-config.json")

TOGGLE_MAP = (
    ("bloom_enabled", "bloom"),
    ("trail_enabled", "cursor-trail"),
    ("glitch_enabled", "cursor-glitch"),
    ("crt_enabled", "terminal-crt"),
)

DEFAULT_CONFIG = {
    "bloom_enabled": True,
    "bloom_strength": 1.45,
    "bloom_radius": 3.2,
    "glyph_lift": 1.15,
    "trail_enabled": True,
    "trail_style": "blaze-spear",
    "trail_color": "#ff7800",
    "trail_duration": 0.36,
    "trail_size": 1.00,
    "trail_opacity": 1.00,
    "trail_bloom_enabled": True,
    "trail_bloom_strength": 0.44,
    "trail_bloom_radius": 0.8,
    "trail_glitch_enabled": True,
    "trail_glitch_strength": 0.013,
    "trail_glitch_static": 0.017,
    "trail_aberration_enabled": True,
    "trail_aberration_strength": 0.0022,
    "glitch_enabled": True,
    "glitch_strength": 0.031,
    "glitch_duration": 0.34,
    "glitch_radius": 0.11,
    "crt_enabled": True,
    "scanline_strength": 0.32,
    "scanline_spacing": 1.6,
    "vignette_strength": 0.20,
    "aberration_strength": 0.0005,
}

CLI_PRESETS = {
    "off": {
        "bloom_enabled": False,
        "trail_enabled": False,
        "trail_bloom_enabled": False,
        "trail_glitch_enabled": False,
        "trail_aberration_enabled": False,
        "glitch_enabled": False,
        "crt_enabled": False,
    },
    "subtle": {
        "bloom_enabled": True,
        "bloom_strength": 0.95,
        "bloom_radius": 2.4,
        "glyph_lift": 1.08,
        "trail_enabled": False,
        "trail_color": "#00f5ff",
        "trail_bloom_enabled": False,
        "trail_glitch_enabled": False,
        "trail_aberration_enabled": False,
        "glitch_enabled": False,
        "crt_enabled": False,
    },
    "terminal": {
        "bloom_enabled": True,
        "bloom_strength": 1.25,
        "bloom_radius": 2.8,
        "glyph_lift": 1.12,
        "trail_enabled": True,
        "trail_color": "#00f5ff",
        "trail_duration": 0.25,
        "trail_size": 0.80,
        "trail_opacity": 0.08,
        "trail_bloom_enabled": False,
        "trail_glitch_enabled": False,
        "trail_aberration_enabled": False,
        "glitch_enabled": False,
        "glitch_strength": 0.040,
        "glitch_duration": 0.25,
        "glitch_radius": 0.10,
        "crt_enabled": True,
        "scanline_strength": 0.28,
        "scanline_spacing": 1.6,
        "vignette_strength": 0.16,
        "aberration_strength": 0.0004,
    },
    "full": {
        "bloom_enabled": True,
        "bloom_strength": 1.45,
        "bloom_radius": 3.2,
        "glyph_lift": 1.15,
        "trail_enabled": True,
        "trail_color": "#ff7800",
        "trail_duration": 0.36,
        "trail_size": 1.00,
        "trail_opacity": 1.00,
        "trail_bloom_enabled": True,
        "trail_bloom_strength": 0.44,
        "trail_bloom_radius": 0.8,
        "trail_glitch_enabled": True,
        "trail_glitch_strength": 0.013,
        "trail_glitch_static": 0.017,
        "trail_aberration_enabled": True,
        "trail_aberration_strength": 0.0022,
        "glitch_enabled": True,
        "glitch_strength": 0.031,
        "glitch_duration": 0.34,
        "glitch_radius": 0.11,
        "crt_enabled": True,
        "scanline_strength": 0.32,
        "scanline_spacing": 1.6,
        "vignette_strength": 0.20,
        "aberration_strength": 0.0005,
    },
}

GUI_PRESET_LABELS = {
    "Full Stack": "full",
    "Terminal Classic": "terminal",
    "Subtle Glow": "subtle",
    "Clean (All Off)": "off",
}

PRESETS = {label: CLI_PRESETS[key] for label, key in GUI_PRESET_LABELS.items()}

BLOOM_INTENSITY = {
    "subtle": (0.95, 2.4),
    "medium": (1.45, 3.2),
    "intense": (2.20, 4.2),
}

PRESET_INTENSITY = {
    "off": None,
    "subtle": "subtle",
    "terminal": "medium",
    "full": "intense",
}

DEFAULT_TRAIL_STYLE = "blaze-spear"
COMET_SMEAR_STYLE = "comet-smear"

TRAIL_STYLES = (
    ("blaze-spear", "Blaze Spear"),
    ("blaze-ribbon", "Blaze Ribbon"),
    ("blaze-core", "Blaze Core"),
    ("frost-blaze", "Frost Blaze"),
    ("comet-smear", "Comet Smear"),
    ("hex-smear", "Hex Smear"),
    ("hex-fade", "Hex Fade"),
    ("hex-gradient", "Hex Gradient"),
    ("hex-rainbow", "Hex Rainbow"),
    ("sparks", "Sparks"),
    ("party-sparks", "Party Sparks"),
    ("blaze-sparks", "Blaze Sparks"),
    ("ink-slash", "Ink Slash"),
    ("zoom-punch", "Zoom Punch"),
    ("letter-zoom", "Letter Zoom"),
    ("plasma-border", "Plasma Border"),
    ("screen-shake", "Screen Shake"),
)

TRAIL_STYLE_IDS = {sid for sid, _label in TRAIL_STYLES}


def resolve_trail_style(style):
    if style in TRAIL_STYLE_IDS:
        return style
    return DEFAULT_TRAIL_STYLE


def trail_style_path(theme_root, style_id):
    return os.path.join(theme_root, "shaders", "trails", f"{style_id}.glsl")


def accent_from_trail_color(r, g, b):
    return min(1.0, r * 0.25 + 0.75), g * 0.15, b * 0.10


def hex_to_rgb(hex_str):
    hex_str = str(hex_str).strip().lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join(c * 2 for c in hex_str)
    if len(hex_str) == 6:
        try:
            r = int(hex_str[0:2], 16) / 255.0
            g = int(hex_str[2:4], 16) / 255.0
            b = int(hex_str[4:6], 16) / 255.0
            return r, g, b
        except ValueError:
            pass
    return 0.0, 0.9608, 1.0


def parse_set_value(val_str):
    lowered = val_str.lower()
    if lowered in ("true", "yes", "on"):
        return True
    if lowered in ("false", "no", "off"):
        return False
    try:
        return float(val_str) if "." in val_str else int(val_str)
    except ValueError:
        return val_str


def load_raw_config(config_file=CONFIG_FILE):
    if os.path.exists(config_file):
        try:
            with open(config_file, "r") as f:
                data = json.load(f)
            if isinstance(data, dict):
                return data
        except (OSError, json.JSONDecodeError):
            pass
    return {}


def load_config(config_file=CONFIG_FILE):
    cfg = dict(DEFAULT_CONFIG)
    cfg.update(load_raw_config(config_file))
    return cfg


def save_config(cfg, config_file=CONFIG_FILE):
    os.makedirs(os.path.dirname(config_file), exist_ok=True)
    new_json = json.dumps(cfg, indent=2)
    old_json = ""
    if os.path.exists(config_file):
        try:
            with open(config_file, "r") as f:
                old_json = f.read()
        except OSError:
            pass
    if new_json != old_json:
        with open(config_file, "w") as f:
            f.write(new_json)
        return True
    return False


def sync_toggles(cfg, toggle_dir=TOGGLE_DIR, only_present_keys=False):
    os.makedirs(toggle_dir, exist_ok=True)
    for key, filename in TOGGLE_MAP:
        if only_present_keys and key not in cfg:
            continue
        path = os.path.join(toggle_dir, filename)
        if cfg.get(key):
            if not os.path.exists(path):
                open(path, "a").close()
        elif os.path.exists(path):
            os.remove(path)


def apply_cli_preset(name, toggle_dir=TOGGLE_DIR, config_file=CONFIG_FILE):
    if name not in CLI_PRESETS:
        raise ValueError(f"Unknown preset: {name}")
    os.makedirs(toggle_dir, exist_ok=True)
    for entry in os.listdir(toggle_dir):
        os.remove(os.path.join(toggle_dir, entry))
    cfg = load_config(config_file)
    cfg.update(CLI_PRESETS[name])
    save_config(cfg, config_file)
    sync_toggles(cfg, toggle_dir)
    intensity = PRESET_INTENSITY[name]
    if intensity:
        with open(os.path.join(toggle_dir, "bloom-intensity"), "w") as f:
            f.write(intensity + "\n")
    return cfg


def apply_bloom_intensity(cfg, toggle_dir=TOGGLE_DIR):
    intensity_file = os.path.join(toggle_dir, "bloom-intensity")
    if not os.path.exists(intensity_file):
        return cfg
    try:
        with open(intensity_file, "r") as f:
            lvl = f.read().strip()
    except OSError:
        return cfg
    if lvl in BLOOM_INTENSITY:
        cfg["bloom_strength"], cfg["bloom_radius"] = BLOOM_INTENSITY[lvl]
    return cfg


def config_from_toggles(toggle_dir=TOGGLE_DIR):
    cfg = dict(DEFAULT_CONFIG)
    for key, filename in TOGGLE_MAP:
        cfg[key] = os.path.exists(os.path.join(toggle_dir, filename))
    return cfg


def merge_runtime_config(toggle_dir=TOGGLE_DIR, config_file=CONFIG_FILE):
    cfg = config_from_toggles(toggle_dir)
    saved = load_config(config_file)
    cfg.update(saved)
    for key, filename in TOGGLE_MAP:
        cfg[key] = os.path.exists(os.path.join(toggle_dir, filename))
    return apply_bloom_intensity(cfg, toggle_dir)


def _sub_float(content, name, value, fmt):
    return re.sub(
        rf"const float {name} = [0-9.]+;",
        f"const float {name} = {value:{fmt}};",
        content,
    )


def _sub_vec4(content, name, r, g, b, a=1.0):
    return re.sub(
        rf"(const\s+)?vec4 {name} = vec4\([^;]+\);",
        f"const vec4 {name} = vec4({r:.4f}, {g:.4f}, {b:.4f}, {a:.4f});",
        content,
    )


def _patch_comet_smear(content, cfg, tr, tg, tb):
    content = re.sub(
        r"vec4 TRAIL_COLOR = vec4\(sRGBToLinear\(vec3\([0-9., ]+\)\), [0-9.]+\);",
        f"vec4 TRAIL_COLOR = vec4(sRGBToLinear(vec3({tr:.4f}, {tg:.4f}, {tb:.4f})), {cfg['trail_opacity']:.4f});",
        content,
    )
    content = _sub_float(content, "DURATION", cfg["trail_duration"], ".4f")
    content = _sub_float(content, "TRAIL_SIZE", cfg["trail_size"], ".4f")
    tb_en = 1.0 if cfg.get("trail_bloom_enabled", False) else 0.0
    content = _sub_float(content, "TRAIL_BLOOM_ENABLED", tb_en, ".1f")
    content = _sub_float(content, "TRAIL_BLOOM_STRENGTH", cfg.get("trail_bloom_strength", 0.80), ".4f")
    content = _sub_float(content, "TRAIL_BLOOM_RADIUS", cfg.get("trail_bloom_radius", 2.5), ".2f")
    tg_en = 1.0 if cfg.get("trail_glitch_enabled", False) else 0.0
    content = _sub_float(content, "TRAIL_GLITCH_ENABLED", tg_en, ".1f")
    content = _sub_float(content, "TRAIL_GLITCH_STRENGTH", cfg.get("trail_glitch_strength", 0.035), ".4f")
    content = _sub_float(content, "TRAIL_GLITCH_STATIC", cfg.get("trail_glitch_static", 0.020), ".4f")
    ta_en = 1.0 if cfg.get("trail_aberration_enabled", False) else 0.0
    content = _sub_float(content, "TRAIL_ABERRATION_ENABLED", ta_en, ".1f")
    return _sub_float(
        content, "TRAIL_ABERRATION_STRENGTH", cfg.get("trail_aberration_strength", 0.0030), ".5f"
    )


def _patch_generic_trail(content, cfg, tr, tg, tb):
    content = _sub_float(content, "DURATION", cfg["trail_duration"], ".4f")
    content = re.sub(
        r"#define ZOOM_DURATION [0-9.]+",
        f"#define ZOOM_DURATION {cfg['trail_duration']:.4f}",
        content,
    )
    content = _sub_vec4(content, "TRAIL_COLOR", tr, tg, tb, 1.0)
    ar, ag, ab = accent_from_trail_color(tr, tg, tb)
    return _sub_vec4(content, "TRAIL_COLOR_ACCENT", ar, ag, ab, 1.0)


_UNFOCUS_GATE = """
    // Unfocus turns a bar into a hollow block and would freeze the last trail.
    if (iFocus == 0) {
        fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
        return;
    }
"""


def _gate_unfocused(content):
    if "if (iFocus == 0)" in content:
        return content
    patched, n = re.subn(
        r"(void mainImage\s*\([^)]*\)\s*\{)",
        r"\1" + _UNFOCUS_GATE,
        content,
        count=1,
    )
    if n != 1:
        raise ValueError("failed to inject unfocus gate into trail shader")
    return patched


def patch_trail_shader(theme_root, cfg):
    style_id = resolve_trail_style(cfg.get("trail_style"))
    source = trail_style_path(theme_root, style_id)
    if not os.path.exists(source):
        source = trail_style_path(theme_root, DEFAULT_TRAIL_STYLE)
    if not os.path.exists(source):
        return None
    with open(source, "r") as f:
        content = f.read()
    tr, tg, tb = hex_to_rgb(cfg.get("trail_color", "#ff7800"))
    if style_id == COMET_SMEAR_STYLE:
        content = _patch_comet_smear(content, cfg, tr, tg, tb)
    else:
        content = _patch_generic_trail(content, cfg, tr, tg, tb)
    return _gate_unfocused(content)


def patch_shader_sources(theme_root, cfg):
    patched = {}
    shaders = os.path.join(theme_root, "shaders")

    glow = os.path.join(shaders, "neon-glow.glsl")
    if os.path.exists(glow):
        with open(glow, "r") as f:
            content = f.read()
        content = _sub_float(content, "BLOOM_STRENGTH", cfg["bloom_strength"], ".4f")
        content = _sub_float(content, "BLOOM_RADIUS", cfg["bloom_radius"], ".4f")
        content = _sub_float(content, "GLYPH_LIFT", cfg["glyph_lift"], ".4f")
        patched["neon-glow.glsl"] = content

    trail = patch_trail_shader(theme_root, cfg)
    if trail is not None:
        patched["cursor-trail.glsl"] = trail

    glitch = os.path.join(shaders, "cursor-glitch.glsl")
    if os.path.exists(glitch):
        with open(glitch, "r") as f:
            content = f.read()
        content = _sub_float(content, "TEAR_STRENGTH", cfg["glitch_strength"], ".4f")
        content = _sub_float(content, "GLITCH_DURATION", cfg["glitch_duration"], ".4f")
        content = _sub_float(content, "GLITCH_RADIUS", cfg["glitch_radius"], ".4f")
        patched["cursor-glitch.glsl"] = content

    crt = os.path.join(shaders, "crt-scanlines.glsl")
    if os.path.exists(crt):
        with open(crt, "r") as f:
            content = f.read()
        content = _sub_float(content, "SCANLINE_STRENGTH", cfg["scanline_strength"], ".4f")
        content = _sub_float(content, "SCANLINE_SPACING", cfg.get("scanline_spacing", 2.0), ".1f")
        content = _sub_float(content, "VIGNETTE", cfg["vignette_strength"], ".4f")
        content = _sub_float(content, "ABERRATION", cfg["aberration_strength"], ".5f")
        patched["crt-scanlines.glsl"] = content

    return patched


def write_if_changed(target_path, new_content):
    old_content = ""
    if os.path.exists(target_path):
        try:
            with open(target_path, "r") as f:
                old_content = f.read()
        except OSError:
            pass
    if new_content != old_content:
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w") as f:
            f.write(new_content)
        return True
    return False


def sync_theme_shaders(theme_root, state_dir=STATE_DIR, toggle_dir=TOGGLE_DIR):
    config_file = os.path.join(state_dir, "fx-config.json")
    cfg = merge_runtime_config(toggle_dir, config_file)
    os.makedirs(state_dir, exist_ok=True)
    save_config(cfg, config_file)

    dest_dirs = [
        os.path.expanduser("~/.local/state/omarchy/current/theme/shaders"),
        os.path.expanduser("~/.config/omarchy/current/theme/shaders"),
        os.path.join(state_dir, "shaders"),
    ]
    patched = patch_shader_sources(theme_root, cfg)
    any_changed = False
    for dest in dest_dirs:
        os.makedirs(dest, exist_ok=True)
        for name, content in patched.items():
            if write_if_changed(os.path.join(dest, name), content):
                any_changed = True

    flag_file = os.path.join(state_dir, ".shaders_changed")
    if any_changed:
        open(flag_file, "a").close()
    elif os.path.exists(flag_file):
        os.remove(flag_file)
    return any_changed
