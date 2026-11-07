local actions, bindings = {}, {}
local directory, created, failure
rex = {
  bind = function(key, action) bindings[key] = action end,
  action = function(action) actions[action.name] = action end,
  layout = { block = function(block) return block end },
  block = { call = function() return { pwd = directory } end },
  session = {
    describe_block = function(args)
      assert(args.block_id == "source-pane")
      return { block = { window_id = "source-tab" } }
    end,
    new_layer = function(args)
      if failure then return nil, failure end
      created = args
      return { layer_id = "lazygit-layer" }
    end,
  },
}

dofile("rex/.config/rex/init.lua")
assert(bindings["ctrl+a>shift+g"] == "floating_lazygit", "Missing lazygit shortcut")
local action = assert(actions.floating_lazygit, "Missing lazygit action")

for reported, expected in pairs({
  ["file://Mac.local/Users/zach/My%20Repo%25"] = "/Users/zach/My Repo%",
  ["/Users/zach/My Repo"] = "/Users/zach/My Repo",
  ["file:///Users/zach/%E6%97%A5%E6%9C%AC"] = "/Users/zach/日本",
}) do
  directory, created = reported, nil
  assert(action.run({ block_id = "source-pane" }).layer_id == "lazygit-layer")
  assert(created.window_id == "source-tab")
  assert(created.focus == true)
  assert(created.layout.flavor == "com.superlogical.terminal.shell")
  assert(created.layout.options.command[1] == "lazygit")
  assert(created.layout.options.cwd == expected)
end

for _, reported in ipairs({ false, "relative/path", "file://Mac.local" }) do
  directory, created = reported, nil
  assert(not pcall(action.run, { block_id = "source-pane" }))
  assert(created == nil, "Invalid directory must not create a pane")
end
directory, failure = "/Users/zach/repo", "Could not start lazygit"
local ok, err = pcall(action.run, { block_id = "source-pane" })
assert(not ok and tostring(err):find(failure, 1, true), "Launch error must propagate")
print("Floating lazygit checks passed")
