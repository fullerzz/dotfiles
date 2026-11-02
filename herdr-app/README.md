# Herdr App

Personal settings, keybindings, the Catppuccin theme, and personal mods, stored under
`.config/herdr-app/` for GNU Stow.

From the dotfiles repository:

```sh
stow --simulate --verbose --no-folding --target="$HOME" herdr-app
stow --verbose --no-folding --target="$HOME" herdr-app
```

Use `--no-folding` so Herdr's runtime files stay outside the repository even on
a fresh machine. Back up any existing destination files before linking; Stow
will refuse to overwrite them.

Session data, window/view state, shared state, installed assets, caches, and
telemetry stay local. The migrated layout and mods also remain local: these
files alone do not recreate that layout. The custom `legacy-keys` bindings
require the corresponding mod to be installed on another machine. The font
setting requires BerkeleyMono Nerd Font Mono.

Herdr may replace symlinks when saving settings; after UI edits, check the links
and `git diff` before assuming those edits reached this repository.

## Atuin Threads

The `personal` layout has a **Threads** button beside **Files** and **Changes**
that opens the right panel. Click it again to hide the panel; the selection is
remembered per space. **Cmd+Shift+T** also opens the threads popup. Click a
session to resume it in a new tab; Shift-click to fork it. Requires Atuin
18.24.3 or later with threads enabled (`atuin config enable threads`).

`personal-tabs` clones Herdr's shipped tab bar (0.1.12) to add the Threads
button. It does not receive upstream tab bar updates automatically.

The button uses the supplied full-color Atuin turtle, saved as
`mods/atuin-threads/atuin-turtle.svg`. Herdr's image loader skips symlinked
assets, so after Stow, create its local rendering copy from the dotfiles repo:

```sh
mkdir -p "$HOME/.config/herdr-app/art"
install -m 644 herdr-app/.config/herdr-app/mods/atuin-threads/atuin-turtle.svg "$HOME/.config/herdr-app/art/atuin-turtle.svg"
```

Vendored from [atuinsh/herdr-atuin-threads](https://github.com/atuinsh/herdr-atuin-threads)
at commit `6e2786d1ae7555cbe4c338c55c265badc86812cb`, with its MIT license.
Local styling adds 10px rounded corners with clipped contents; preserve it on updates.
To update, copy upstream's `main.js`, `mod.json`, and `threads.svg` into
`.config/herdr-app/mods/atuin-threads/`, retain the license, update this revision,
and run `herdr-app check ~/.config/herdr-app/mods/atuin-threads`.

Stow with `--no-folding` as above so generated type files and optional
machine-specific `local.json` stay outside the repo. The popup runs Atuin and
local Git commands; it lists up to 80 recent threads before filtering by space.

## Eza Files panel

The `personal` layout is a clone of Herdr's shipped `main` layout (0.1.10). Its
right-hand **Files** panel uses the `eza-files` mod and **Changes** uses
`difftastic-changes`. Herdr replaces shipped layouts and mods on
every start, so the change needs both clones. Switch with
`herdr-app do layout.switch --name personal` (or **Ctrl+Shift+L**).

`eza-files` is the shipped `files` mod with Nerd Font icons and colors from
`eza -1 -a --icons=always --color=always`. Colors follow `LS_COLORS` or eza's
theme, mapped onto the Herdr theme's ANSI colors where eza emits basic colors.
`eza` runs on the space's machine in the same shell call as the folder listing.
Without `eza`, or for names eza escapes, rows fall back to the shipped SVG
icons. Glyphs use the terminal font from `settings.json` (a Nerd Font); set
`ICON_FONT` in `main.js` to override it. Windows folders keep the SVG icons.

Shipped layout updates do not reach `personal`. To rebase after a Herdr update,
re-clone `main` and point the `files` block's `content.mod` to `eza-files`.

Validate with `herdr-app check ~/.config/herdr-app/mods/eza-files` and
`node --test herdr-app/tests/eza-files.test.mjs` (set `EZA_DIR` to eza's folder
if `eza` on PATH is a shim that cannot run).

## Tmux prefix

Press **Ctrl+A**, then a key: `c` opens a tab, `%` / `"` split right / down,
`n` / `p` switch tabs, `h j k l` or arrows focus panes, `J` / `K` switch
spaces, and `z` toggles zoom. `?` shows all bindings; Escape cancels.
Repeatable actions allow another key within 500 ms.

**Ctrl+A, Shift+G** opens lazygit in a floating terminal using the focused
terminal's current directory and its space's machine. Press `q` in lazygit or
click **Close** to exit; closing the overlay ends its lazygit process. Requires
`lazygit` on that machine. Alt+G retains the existing legacy split behavior.

**Ctrl+A Ctrl+A** sends literal Ctrl+A to the terminal (for example, shell
beginning-of-line). Ctrl+B remains available to terminal programs. This replaces
the `legacy-keys` Ctrl+A opener with the new mod's bindings; the local legacy mod
remains installed for its other uses, including Alt+G.

Vendored from [herdrdev/herdr-layout-examples/tmux-prefix](https://github.com/herdrdev/herdr-layout-examples/tree/ed4eda7a02e255191203df0ff04b9dc7ae56e1ad/tmux-prefix)
at commit `ed4eda7a02e255191203df0ff04b9dc7ae56e1ad`, with its Apache-2.0 license.
Local changes replace Ctrl+B with Ctrl+A in the keybindings, key handler,
literal-key forwarding, and displayed hints, and add floating lazygit.
Preserve those changes on updates.

Install with the Stow command above, then validate with
`herdr-app check ~/.config/herdr-app/mods/tmux-prefix`.
The mod runs `hc keys` to forward literal keys, including to remote terminals.
During repeats, only simple ASCII keys and basic navigation keys are replayed;
shifted symbols, Unicode, and modified shortcuts are not replayed.

Run the launch/cleanup regression check with `node --test herdr-app/tests/tmux-prefix.test.mjs`.

## Difftastic Changes panel

`difftastic-changes` clones Herdr's Changes mod (0.1.11), keeping its file list,
refresh behavior, and commit controls. Git runs the configured `diff.external`
(`difft` here) with colored inline output. The panel preserves difftastic's line
numbers, colors, and syntax emphasis; Git still supplies the file counts.
Untracked files compare against `/dev/null`. Previews show at most 1,500 lines
and 4,000 visible characters per line, with a truncation notice.

The `personal` layout references this mod. For another personal layout, set the
Changes block's `content.mod` to `difftastic-changes`. Clones do not receive
upstream mod updates. Requires `env`, Git, and the configured external diff on
the space's machine (macOS/Linux); external tool errors appear in the preview.
The existing Commit button still stages all changes and commits them.

Validate with `node --test herdr-app/tests/difftastic-changes.test.mjs` and
`herdr-app check ~/.config/herdr-app/mods/difftastic-changes`. Run the checker on
the installed directory so its generated type files stay outside dotfiles.
