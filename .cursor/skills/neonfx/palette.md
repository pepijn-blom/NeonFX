# NeonFX palette

## Core roles

| Role | Hex | Used for |
|------|-----|----------|
| Background | `#0c0018` | Terminal, desktop void |
| Foreground (terminal) | `#00f5ff` | Default text, git plain/header, lazygit default, fzf fg |
| Foreground (desktop) | `#ece6ff` | waybar, walker, btop main text |
| Bright cyan | `#66faff` | color15, bat keys/tags, fish keywords, eza dirs, fzf fg+ |
| Accent / selection | `#ff0099` | fish commands, selection bg, starship success |
| Pink highlight | `#ff33aa` | git changed/untracked, fish redirection, starship branch |
| Magenta param | `#ff66cc` | fish params/operators |
| Mint | `#33ffb8` | numbers, git added, eza executables, fish cwd |
| Red error | `#ff3366` | errors, git deleted |
| Muted purple | `#5a3a88` | punctuation, borders, autosuggestions |
| Soft purple | `#7a6a98` | comments, labels |
| Lavender (contrast) | `#ffb3e6` | bat strings, markdown in eza — not default terminal text |
| Cursor | `#00f5ff` | ghostty cursor, bat caret |

Full 16-color slots: `colors.toml` (mirror in `ghostty.conf` `palette =` lines).

## File → color mapping

### `colors.toml` / `ghostty.conf`
- `foreground`, `color7` → default text
- `color6`, `cursor` → cyan accent slot
- `color14`, `color15` → bright cyan
- `color5`, `accent`, `selection_background` → magenta

### `fish.conf`
- `fish_color_normal`, `fish_color_option` → `00f5ff`
- `fish_color_command`, `fish_color_end` → `ff0099`
- `fish_color_keyword`, `fish_color_escape` → `66faff`
- `fish_color_cwd` → `33ffb8`
- `fish_color_quote` → `00ff9f`
- `fish_color_redirection`, `fish_color_match` → `ff33aa`

### `bat/NeonFX.tmTheme`
- Default `foreground` → `#00f5ff`
- JSON/YAML/HTML keys, markup headings → `#66faff`
- Strings → `#ffb3e6`
- Numbers → `#33ffb8`
- Constants/booleans → `#ff33aa`
- Punctuation → `#5a3a88`
- Variables → `#ece6ff`

### `starship.toml` palette
- `foreground` → `cyan` (`#00f5ff`)
- `directory` style → `bold bright_cyan` (`#66faff`)
- `git_branch` → `bold italic pink`
- `git_status` → `mint`

### `cli.env.sh` / `fish.conf` EXA_COLORS
- `di` (dirs) → 102,250,255 (`#66faff`)
- `fi` (files) → 0,245,255 (`#00f5ff`)
- `ex` (executables) → 51,255,184 (`#33ffb8`)
- `ln` (symlinks) → 255,51,170 (`#ff33aa`)
- `*.md` → 255,179,230 (`#ffb3e6`)

### `git.conf`
- Plain text, headers, commits → `#00f5ff`
- Branches/refs → `#00f5ff` / `#66faff`
- Added → `#33ffb8`; changed/untracked → `#ff33aa`; old → `#ff3366`

## When changing one color

1. Decide if it's **default text** (wide sync) or **accent** (targeted files).
2. Update `colors.toml` + `ghostty.conf` if it's a palette slot or foreground.
3. Grep the repo for the old hex (with and without `#`).
4. Re-apply hook; `bat cache --build` if bat changed.
5. Offer `./bin/neonfx-color-samples` for visual check (HTML, not ANSI).
