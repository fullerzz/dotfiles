// A lazy file browser for the focused pane's folder, with bounded read-only previews.
// Cloned from Herdr's shipped `files` mod (0.1.10). Icons and colors come from `eza`
// on the space's machine; without eza, or for names it escapes, the shipped SVGs show.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState } from "gpui-base";
import { spaces, panes, focused, exec, readTextFile, watchFolder, theme, settings, window } from "herdr";

function location() {
  const space = spaces().find(s => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on, space: space?.id };
}
const key = () => JSON.stringify(location());
const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const PER_FOLDER = 500, TOTAL = 5000;
// Font for eza's Nerd Font glyphs; null uses the terminal font from settings.json.
const ICON_FONT = null;

// One SGR color as a theme ANSI name ("ansi4") or "#rrggbb".
function xterm(n) {
  if (n < 16) return `ansi${n}`;
  const hex = v => v.toString(16).padStart(2, "0");
  if (n >= 232) { const v = 8 + (n - 232) * 10; return `#${hex(v)}${hex(v)}${hex(v)}`; }
  const c = n - 16, level = v => (v === 0 ? 0 : 55 + v * 40);
  return `#${hex(level(Math.floor(c / 36)))}${hex(level(Math.floor(c / 6) % 6))}${hex(level(c % 6))}`;
}

function applySgr(params, state) {
  const codes = params === "" ? [0] : params.split(";").map(Number);
  for (let i = 0; i < codes.length; i++) {
    const c = codes[i];
    if (c === 0) { state.fg = null; state.bold = false; }
    else if (c === 1) state.bold = true;
    else if (c === 22) state.bold = false;
    else if (c >= 30 && c <= 37) state.fg = `ansi${c - 30}`;
    else if (c >= 90 && c <= 97) state.fg = `ansi${c - 82}`;
    else if (c === 39) state.fg = null;
    else if (c === 38 || c === 48) {
      let color = null;
      if (codes[i + 1] === 5) { color = xterm(codes[i + 2] ?? 0); i += 2; }
      else if (codes[i + 1] === 2) {
        color = "#" + codes.slice(i + 2, i + 5).map(v => (v ?? 0).toString(16).padStart(2, "0")).join("");
        i += 4;
      }
      if (c === 38) state.fg = color;
    }
  }
}

// `eza -1 --icons=always --color=always` text: name -> { icon, color, bold }.
function parseEza(text, names) {
  const out = new Map();
  for (const line of text.split("\n")) {
    if (!line) continue;
    const state = { fg: null, bold: false };
    let plain = "", iconColor, nameColor, nameBold, pos = 0;
    for (const m of line.matchAll(/\x1b\[([0-9;]*)m/g)) {
      plain += line.slice(pos, m.index);
      applySgr(m[1], state);
      pos = m.index + m[0].length;
      // The glyph is the first visible character; the name starts two code points later.
      const seen = Array.from(plain).length;
      if (seen === 0) iconColor = state.fg;
      if (seen <= 2) { nameColor = state.fg; nameBold = state.bold; }
    }
    plain += line.slice(pos);
    const chars = Array.from(plain);
    if (chars.length < 3 || chars[1] !== " ") continue;
    const rest = chars.slice(2).join("");
    // Symlinks print "name -> target"; take the longest prefix that is a listed name.
    // Some eza versions quote names with spaces despite --no-quotes.
    const known = s => names.has(s) ? s : /^'.*'$/.test(s) && names.has(s.slice(1, -1)) ? s.slice(1, -1) : null;
    let name = known(rest);
    for (let i = rest.lastIndexOf(" -> "); !name && i > 0; i = rest.lastIndexOf(" -> ", i - 1)) name = known(rest.slice(0, i));
    if (name) out.set(name, { icon: chars[0], color: iconColor ?? nameColor ?? null, nameColor: nameColor ?? null, bold: Boolean(nameBold) });
  }
  return out;
}

async function directory(path, on) {
  if (!on && window()?.platform === "windows") {
    const r = await exec("powershell", ["-NoProfile", "-Command", "& { param($p) @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Where-Object Name -ne '.git' | Select-Object -First 501 | ForEach-Object { @{ name=$_.Name; dir=($_.PSIsContainer -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)) } }) | ConvertTo-Json -Compress } '" + path.replaceAll("'", "''") + "'"]);
    if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
    const result = JSON.parse(r.stdout || "[]");
    return Array.isArray(result) ? result : [result];
  }
  // eza's text first (it never contains NUL), then one NUL, then the NUL-separated listing.
  const script = 'if command -v eza >/dev/null 2>&1; then eza -1 -a --icons=always --color=always --no-quotes -- "$1" 2>/dev/null | head -n 2000; fi; printf "\\0"; n=0; for p in "$1"/* "$1"/.[!.]* "$1"/..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; name=${p##*/}; [ "$name" = .git ] && continue; if [ -d "$p" ] && [ ! -L "$p" ]; then kind=d; else kind=f; fi; printf "%s\\0%s\\0" "$kind" "$name"; n=$((n+1)); [ "$n" -gt 500 ] && break; done; test -d "$1"';
  const r = await exec("sh", ["-c", script, "files", path], { on });
  if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
  const split = r.stdout.indexOf("\0");
  const fields = r.stdout.slice(split + 1).split("\0"), out = [];
  for (let i = 0; i + 1 < fields.length; i += 2) out.push({ name: fields[i + 1], dir: fields[i] === "d" });
  const icons = parseEza(r.stdout.slice(0, Math.max(0, split)), new Set(out.map(e => e.name)));
  for (const entry of out) entry.eza = icons.get(entry.name) ?? null;
  return out;
}

const paint = (color, t) => (!color ? null : color.startsWith("#") ? color : t[color] ?? null);

export default class Files extends View {
  init(_props, cx) {
    this.saved = new Map();
    this.entries = new Map(); this.folders = new Set(); this.pending = new Set(); this.marks = {};
    this.refresh(cx);
    cx.timer.every(10000, cx => this.refresh(cx));
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    const context = this.context;
    cx.spawn(async cx => {
      try { while (this.context === context) { await watchFolder(root); if (this.current(context)) this.refresh(cx); } }
      catch { if (this.context === context) this.watched = null; }
    });
  }

  current(context) {
    return this.context === context && key() === context.key;
  }

  async loadFolder(path, context) {
    const { on, cwd: root } = context;
    const entries = await directory(path ? `${root}/${path}` : root, on);
    if (!this.current(context) || (path && !this.folders.has(path))) return;
    const used = [...this.entries.entries()].filter(([p]) => p !== path).reduce((n, [, e]) => n + e.length, 0);
    this.entries.set(path, entries.slice(0, Math.max(0, Math.min(PER_FOLDER, TOTAL - used))).sort((a, b) => Number(b.dir) - Number(a.dir) || a.name.localeCompare(b.name)));
    if (entries.length > PER_FOLDER || used + entries.length > TOTAL) this.limited = true;
  }

  refresh(cx) {
    const { cwd, on } = location(), next = key();
    if (next !== this.context?.key) {
      if (this.context) this.saved.set(this.context.key, { folders: this.folders, file: this.file });
      const saved = this.saved.get(next);
      this.context = { key: next, cwd, on }; this.root = cwd; this.on = on; this.entries = new Map(); this.folders = new Set(saved?.folders);
      this.pending = new Set(); this.marks = {}; this.show(null); this.watched = null; this.error = null; this.limited = false;
      this.loading = false;
      if (saved?.file) this.show(saved.file, cx);
    }
    if (!cwd || this.loading) return;
    const context = this.context;
    this.loading = true;
    this.limited = false;
    cx.spawn(async cx => {
      try {
        for (const path of ["", ...this.folders]) {
          if (!this.current(context)) return;
          await this.loadFolder(path, context);
        }
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null);
        const marks = {};
        if (top?.code === 0) {
          // Writes nothing under .git (index lock, fsmonitor cookie): the folder watch would refresh again.
          const status = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=normal"], { cwd, on }).catch(() => null);
          if (status?.code === 0) for (const entry of status.stdout.split("\0").filter(Boolean).slice(0, TOTAL)) {
            const xy = entry.slice(0, 2);
            marks[`${top.stdout.trim()}/${entry.slice(3)}`] = xy === "??" || xy.includes("A") ? "A" : xy.includes("U") ? "U" : xy.includes("D") ? "D" : "M";
          }
        }
        if (!this.current(context)) return;
        this.marks = marks; this.error = null; this.watch(cwd, cx);
      } catch (e) { if (this.current(context)) this.error = String(e); }
      finally { if (this.context === context) this.loading = false; cx.notify(); }
    });
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) {
        this.folders.delete(folder);
        this.entries.delete(folder);
      }
    } else {
      this.folders.add(path);
      if (!this.entries.has(path) && !this.pending.has(path)) {
        const context = this.context;
        this.pending.add(path);
        cx.spawn(async cx => {
          try { await this.loadFolder(path, context); }
          catch (e) { if (this.current(context)) this.error = String(e); }
          finally { if (this.context === context) this.pending.delete(path); cx.notify(); }
        });
      }
    }
    cx.notify();
  }

  show(path, cx) {
    this.code?.release(); this.code = null; this.file = path; this.fileError = null;
    if (!path || !cx) return;
    const context = this.context, root = this.root, on = this.on;
    cx.spawn(async cx => {
      try {
        const text = await readTextFile(`${root}/${path}`, { on });
        if (this.file !== path || !this.current(context)) return;
        if (text === null) { this.fileError = "This file is no longer available"; return; }
        if (text.includes("\0")) { this.fileError = "Binary file · no text preview"; return; }
        const t = theme(), ext = path.includes(".") ? path.split(".").pop() : "txt";
        this.code = EditorState.new({ language: LANG[ext] ?? ext, readonly: true,
          value: text.length > 400000 ? text.slice(0, 400000) + "\n… (file truncated)" : text,
          font_family: settings().font_family, font_size: 12,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      } catch { if (this.file === path && this.current(context)) this.fileError = "Cannot preview this file (binary, too large, or unreadable)"; }
      finally { cx.notify(); }
    });
  }

  icon(entry, t) {
    if (!entry.eza) return svg(`mods/eza-files/${entry.dir ? "folder" : "file"}.svg`).size(14).flex_none().text_color(t.muted);
    return div().w(16).flex_none().flex().justify_center().font_family(ICON_FONT ?? settings().font_family ?? "JetBrains Mono")
      .text_size(14).text_color(paint(entry.eza.color, t) ?? t.muted).child(entry.eza.icon);
  }

  rows(prefix, depth, out, t) {
    if (out.length >= TOTAL || depth > 40) return out;
    for (const entry of this.entries.get(prefix) ?? []) {
      if (out.length >= TOTAL) break;
      const path = prefix ? `${prefix}/${entry.name}` : entry.name, open = this.folders.has(path), mark = this.marks[`${this.root}/${path}`];
      const nameColor = paint(entry.eza?.nameColor, t);
      out.push(h_flex().id(`file-${path}`).h(28).flex_none().pl(8 + depth * 18).pr(8).gap(7).items_center().rounded(7).cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => entry.dir ? this.toggle(path, cx) : this.show(path, cx))
        .child(entry.dir ? svg(`mods/eza-files/chevron-${open ? "down" : "right"}.svg`).size(12).flex_none().text_color(t.dim) : div().w(12).flex_none())
        .child(this.icon(entry, t))
        .child(div().flex_1().min_w(0).truncate().when(Boolean(nameColor), el => el.text_color(nameColor)).when(Boolean(entry.eza?.bold), el => el.font_semibold()).child(entry.name))
        .when(Boolean(mark), el => el.child(div().text_size(11).text_color(mark === "A" ? t.ansi2 : mark === "D" || mark === "U" ? t.ansi1 : t.blocked).child(mark))));
      if (entry.dir && open) this.rows(path, depth + 1, out, t);
    }
    return out;
  }

  render(cx) {
    if (key() !== this.context?.key) this.refresh(cx);
    const t = theme();
    return v_flex().id("files").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .when(Boolean(this.file), el => el.child(div().id("files-back").w(20).cursor_pointer().text_color(t.muted).on_click((_e, cx) => { this.show(null); cx.notify(); }).child("←")))
        .child(div().font_semibold().child("Files"))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(12).text_color(t.dim).child(this.file ?? this.root?.split(/[\\/]/).pop() ?? "")))
      .when(!this.file, el => el.child(v_flex().id("files-tree").flex_1().min_h(0).overflow_y_scrollbar().p(6).children(this.rows("", 0, [], t))
        .when(Boolean(this.error) || !this.entries.get("")?.length, el => el.child(div().p(8).text_size(12).text_color(t.dim).child(this.error || (this.loading ? "Loading files…" : this.root ? "No files" : "No folder"))))
        .when(this.limited, el => el.child(div().p(8).text_size(11).text_color(t.dim).child("File list limited to 500 entries per folder and 5,000 total")))))
      .when(Boolean(this.file), el => el.child(this.code ? Editor.new(this.code).flex_1().min_h(0) : div().p(12).text_color(t.dim).child(this.fileError || "Loading file…")));
  }
}
