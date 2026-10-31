# Herdr App

Personal settings, keybindings, the Catppuccin theme, and the Atuin Threads mod, stored under
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

Press **Cmd+Shift+T** to open the threads popup. Click a session to resume it in
a new tab; Shift-click to fork it. Requires Atuin 18.24.3 or later with threads
enabled (`atuin config enable threads`).

Vendored unchanged from [atuinsh/herdr-atuin-threads](https://github.com/atuinsh/herdr-atuin-threads)
at commit `6e2786d1ae7555cbe4c338c55c265badc86812cb`, with its MIT license.
To update, copy upstream's `main.js`, `mod.json`, and `threads.svg` into
`.config/herdr-app/mods/atuin-threads/`, retain the license, update this revision,
and run `herdr-app check ~/.config/herdr-app/mods/atuin-threads`.

Stow with `--no-folding` as above so generated type files and optional
machine-specific `local.json` stay outside the repo. The popup runs Atuin and
local Git commands; it lists up to 80 recent threads before filtering by space.
