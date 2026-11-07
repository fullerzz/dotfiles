-- Rex configuration: https://www.superlogical.com/rex/docs/customize/config

rex.action{
  name = "floating_lazygit",
  title = "Open Floating Lazygit",
  run = function(ctx)
    assert(ctx.block_id, "Lazygit needs a focused terminal")
    local source = assert(rex.session.describe_block{ block_id = ctx.block_id })
    local window = assert(source.block.window_id, "The terminal must be in a tab")
    local directory = assert(rex.block.call("com.superlogical.terminal", "pwd", {}))
    local cwd = directory.pwd
    if cwd and cwd:match("^file://") then
      cwd = cwd:match("^file://[^/]*(/.*)$")
      if cwd then
        cwd = cwd:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
      end
    end
    assert(cwd and cwd:sub(1, 1) == "/", "The terminal has not reported an absolute directory")
    return assert(rex.session.new_layer{
      window_id = window,
      bounds = { 0.05, 0.075, 0.9, 0.85 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = { command = { "lazygit" }, cwd = cwd },
      },
    })
  end,
}

-- Match Herdr's tab, pane, and workspace shortcuts.
rex.bind("cmd+w", "client.tab.close")
rex.bind("cmd+shift+w", "pane.close")
rex.bind("cmd+n", "session.new")
rex.bind("cmd+shift+n", "client.window.new")
rex.bind("cmd+b", "client.sidebar.toggle")
rex.bind("f2", "client.tab.rename")
rex.bind("shift+f2", "session.rename")
rex.bind("cmd+alt+]", "session.next")
rex.bind("cmd+alt+[", "session.previous")
rex.bind("shift+left", "client.tab.previous")
rex.bind("shift+right", "client.tab.next")

rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>p", "pane.go_to")
rex.bind("ctrl+a>shift+g", "floating_lazygit")
rex.bind("ctrl+a>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+a>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>x", "client.tab.close")
rex.bind("ctrl+a>left", "pane.focus", { direction = "left", wrap = false })
rex.bind("ctrl+a>right", "pane.focus", { direction = "right", wrap = false })
rex.bind("ctrl+a>up", "pane.focus", { direction = "up", wrap = false })
rex.bind("ctrl+a>down", "pane.focus", { direction = "down", wrap = false })
rex.bind("ctrl+a>shift+j", "session.next")
rex.bind("ctrl+a>shift+k", "session.previous")

for index = 1, 10 do
  rex.bind("ctrl+a>" .. (index % 10), "client.tab.goto", { index = index })
end

-- Press Ctrl+A twice to send Ctrl+A to the terminal.
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
