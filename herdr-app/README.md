# Herdr App

Personal settings, keybindings, and the Catppuccin theme, stored under
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
