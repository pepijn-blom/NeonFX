# NeonFX flavor for Yazi

A synthwave flavor for the [Yazi](https://yazi-rs.github.io/) file manager matching the [NeonFX](https://github.com/pepijn-blom/NeonFX) theme.

## Features

- Deep void purple backgrounds and panels (`#0c0018`, `#1a1030`)
- Bright cyan text (`#00f5ff`) and mint active directories (`#33ffb8`)
- Neon magenta accents and selections (`#ff0099`, `#ff33aa`)
- Muted neon purple borders (`#5a3a88`)
- Syntax-highlighted code previews powered by TextMate theme (`tmtheme.xml`)
- Built-in color rules for `git.yazi` status indicators

## Usage

In `~/.config/yazi/theme.toml`:

```toml
[flavor]
dark = "neonfx"
light = "neonfx"
```
