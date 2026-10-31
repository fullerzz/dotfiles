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
