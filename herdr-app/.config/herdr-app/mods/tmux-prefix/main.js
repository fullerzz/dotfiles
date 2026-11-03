import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { closeOverlay, focused, hc, nextCommand, notify, openOverlay, props, run, spaces, theme } from "herdr";

// Modified from upstream: Ctrl+A prefix and a floating lazygit action.
// Edit these two things to make the example yours. Only repeatable actions
// start a timer: the first key after Ctrl+A can take as long as you like.
const REPEAT_MS = 500;
const BINDINGS = [
  ["c", "New tab", "tab.new"],
  ["G", "Floating lazygit", "lazygit"],
  ["t", "Atuin Threads", "mod.open", { name: "atuin-threads" }],
  ["T", "Sesh picker", "mod.open", { name: "sesh" }],
  ["%", "Split right", "pane.split", { direction: "right" }],
  ['"', "Split down", "pane.split", { direction: "down" }],
  ["x", "Close pane", "pane.close"],
  ["n", "Next tab", "tab.next"],
  ["p", "Previous tab", "tab.prev"],
  ["h", "Focus left", "pane.go", { direction: "left" }, true],
  ["j", "Focus down", "pane.go", { direction: "down" }, true],
  ["k", "Focus up", "pane.go", { direction: "up" }, true],
  ["l", "Focus right", "pane.go", { direction: "right" }, true],
  ["left", "Focus left", "pane.go", { direction: "left" }, true],
  ["down", "Focus down", "pane.go", { direction: "down" }, true],
  ["up", "Focus up", "pane.go", { direction: "up" }, true],
  ["right", "Focus right", "pane.go", { direction: "right" }, true],
  ["J", "Next space", "space.next", {}, true],
  ["K", "Previous space", "space.prev", {}, true],
  ["z", "Zoom pane", "pane.zoom"],
  ["d", "Minimize window", "window.minimize"],
  ...Array.from({ length: 10 }, (_, i) => [String(i), `Tab ${i === 0 ? 10 : i}`, "tab.select", { index: i === 0 ? 10 : i }]),
];

function forwardKey(e, key) {
  if (["enter", "tab", "backspace", "left", "right", "up", "down", "space"].includes(e.key)) return e.key;
  if (key === " ") return "space";
  if (/^[A-Z]$/.test(key)) return `shift+${key.toLowerCase()}`;
  if (key.length === 1 && "abcdefghijklmnopqrstuvwxyz0123456789`\\[],=-.';/".includes(key)) return key === "\\" ? "backslash" : key;
  return null;
}

export default class TmuxPrefix extends View {
  init(_props, cx) {
    this.terminal = props()?.terminal;
    if (this.terminal) return;
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.generation = 0;
    this.all = false;
    // The mod-specific key binding beats the global opener while we're open.
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  async close() {
    this.closed = true;
    if (this.terminal) await hc(["kill", this.terminal]);
  }

  lazygit(cx) {
    if (this.launching) return;
    const target = focused();
    const space = spaces().find((s) => s.id === target?.space);
    const cwd = target?.cwd || space?.folder;
    if (!cwd) {
      notify({ title: "Lazygit", body: "No current directory is available.", level: "error" });
      return;
    }
    this.launching = true;
    this.generation++;
    cx.notify();
    const args = ["run", "--bg", "--json", "--no-notify", "--cwd", cwd];
    if (space?.machine) args.push("--on", space.machine);
    // Finish outside the view task so cancelling the prefix can clean up a late launch.
    hc([...args, "--", "lazygit"]).then(async (result) => {
      if (result.code !== 0) throw new Error(result.stderr || "Could not start lazygit.");
      const { address } = JSON.parse(result.stdout);
      if (!address) throw new Error("Herdr returned no terminal address.");
      if (this.closed) {
        await hc(["kill", address]);
        return;
      }
      try {
        this.dismiss();
        openOverlay({ kind: "dialog", modal: true, width: 0.9, height: 0.85,
          layout: { type: "column", children: [
            { type: "block", size: { px: 32 }, content: { mod: "tmux-prefix", props: { terminal: address } } },
            { type: "block", content: { terminal: address } },
          ] } });
      } catch (error) {
        await hc(["kill", address]);
        throw error;
      }
    }).catch((error) => {
      notify({ title: "Lazygit", body: String(error), level: "error" });
      if (!this.closed) this.dismiss();
    });
  }

  send(key, cx) {
    this.generation++;
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // hc starts its subprocess at the call, before closing cancels this view's tasks.
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`tmux-prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  sendPrefix(cx) {
    this.send("ctrl+a", cx);
  }

  key(e, cx) {
    cx.stop_propagation();
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    if (this.launching) return;
    if (m.control && e.key === "a") return this.sendPrefix(cx);
    const plain = !m.control && !m.alt && !m.platform;
    const key = plain ? (e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key)) : e.key;
    if (plain && key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }
    const binding = plain && BINDINGS.find((b) => b[0] === key);
    if (!binding) {
      const forwarded = this.repeat && plain && forwardKey(e, key);
      if (forwarded) return this.send(forwarded, cx);
      return this.dismiss();
    }
    const [, , command, args = {}, repeatable = false] = binding;
    if (command === "lazygit") return this.lazygit(cx);
    if (!repeatable) this.dismiss();
    run(command, args);
    if (repeatable) {
      this.repeat = true;
      const generation = ++this.generation;
      cx.timer.after(REPEAT_MS, () => {
        if (this.generation === generation) this.dismiss();
      });
      cx.notify();
    }
  }

  render() {
    const t = theme();
    if (this.terminal) {
      return h_flex().size_full().px(12).items_center().justify_between()
        .bg(t.surface).text_color(t.foreground).text_size(12)
        .child("Lazygit · q to quit")
        .child(div().id("close-lazygit").px(8).cursor_pointer()
          .hover((s) => s.bg(t.hover)).on_click(() => this.dismiss()).child("Close"));
    }
    const rows = this.all ? BINDINGS : BINDINGS.filter(([key]) => !["left", "right", "up", "down"].includes(key) && !/^\d$/.test(key));
    return v_flex().id("tmux-prefix").track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between().child(div().font_semibold().child(this.launching ? "Starting lazygit…" : this.repeat ? `Repeat · ${REPEAT_MS} ms` : "Ctrl+A · waiting for a key"))
        .child(div().text_color(t.muted).child("Esc cancel · ^A send prefix")))
      .child(v_flex().h(280).min_h(0).overflow_y_scrollbar().children(rows.map(([key, label, , , repeatable]) =>
        h_flex().h(20).flex_none().items_center().gap(12).child(div().w(40).text_color(t.accent).child(key))
          .child(div().flex_1().child(label)).child(div().text_color(t.dim).child(repeatable ? "repeat" : "")))))
      .child(div().text_color(t.muted).child("0–9 tabs (0 = 10) · arrows focus · ? all bindings"));
  }
}
