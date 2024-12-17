local appearance = require 'appearance'
-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
-- config.font = wezterm.font 'Hack Nerd Font Mono'
config.font = wezterm.font 'FiraCode Nerd Font'
-- config.font = wezterm.font("0xProto Nerd Font Mono")
config.font_size = 13.0
-- For example, changing the color scheme:
config.color_scheme = "catppuccin-mocha"
config.window_background_opacity = 0.95
config.initial_rows = 40
config.initial_cols = 160

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.enable_scroll_bar = true

config.enable_wayland = false

config.set_environment_variables = {
  PATH = '/home/zach/.bin' .. os.getenv('PATH')
}

config.window_frame = {

  -- The size of the font in the tab bar.
  -- Default to 10.0 on Windows but 12.0 on other systems
  font_size = 12.5,
}

config.colors = {
  tab_bar = {
    -- The color of the inactive tab bar edge/divider
    inactive_tab_edge = '#575757',
  },
}

local segment_icons = {
  ["code"] = wezterm.nerdfonts.dev_code,
  ["python"] = wezterm.nerdfonts.dev_python,
  ["go"] = wezterm.nerdfonts.seti_go,
  ["rust"] = wezterm.nerdfonts.linux_ferris,
  ["dotfiles"] = wezterm.nerdfonts.custom_folder_config,
  ["gift"] = wezterm.nerdfonts.oct_gift,
  ["default"] = wezterm.nerdfonts.dev_terminal,
}

local function icon_segment(pane_title)
  -- TODO: Check for hardcoded list of known project dirs
  if pane_title:find("dotfiles") then
    return segment_icons["dotfiles"] .. ' '
  elseif pane_title:find("gurlon") then
    return segment_icons["python"] .. ' '
  elseif pane_title:find("Rust") then
    return segment_icons["rust"] .. ' '
  elseif pane_title:find("Python") then
    return segment_icons["python"] .. ' '
  elseif pane_title:find("Code") then
    return segment_icons["code"] .. ' '
  end
  return segment_icons["default"] .. ' '
end

-- https://alexplescan.com/posts/2024/08/10/wezterm/
-- Upper-right powerline style status bar
local function segments_for_right_status(window)
  return {
    icon_segment(window:active_tab():window():active_pane():get_title()),
    window:active_tab():window():active_pane():get_title(), -- updates with each tab switch
    -- window:active_workspace(),
    wezterm.strftime('%a %b %-d %H:%M'),
    wezterm.hostname() .. ' ' .. wezterm.nerdfonts.cod_terminal_linux,
  }
end
  
wezterm.on('update-status', function(window, _)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local segments = segments_for_right_status(window)

  local color_scheme = window:effective_config().resolved_palette
  -- Note the use of wezterm.color.parse here, this returns
  -- a Color object, which comes with functionality for lightening
  -- or darkening the colour (amongst other things).
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground

  -- Each powerline segment is going to be coloured progressively
  -- darker/lighter depending on whether we're on a dark/light colour
  -- scheme. Let's establish the "from" and "to" bounds of our gradient.
  local gradient_to, gradient_from = bg
  if appearance.is_dark() then
    gradient_from = gradient_to:lighten(0.2)
  else
    gradient_from = gradient_to:darken(0.2)
  end

  -- Yes, WezTerm supports creating gradients, because why not?! Although
  -- they'd usually be used for setting high fidelity gradients on your terminal's
  -- background, we'll use them here to give us a sample of the powerline segment
  -- colours we need.
  local gradient = wezterm.color.gradient(
    {
      orientation = 'Horizontal',
      colors = { gradient_from, gradient_to },
    },
    #segments -- only gives us as many colours as we have segments.
  )

  local segment_text_colors = {
    '#C6A0F6', -- mauve
    '#F5A97F', -- peach
    '#A6DA95', -- green
    '#B7BDF8', -- lavender
    '#8BD5CA' -- teal
  }

  -- We'll build up the elements to send to wezterm.format in this table.
  local elements = {}

  for i, seg in ipairs(segments) do
    local is_first = i == 1

    if is_first then
      table.insert(elements, { Background = { Color = 'none' } })
    end
    table.insert(elements, { Foreground = { Color = gradient[i] } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })

    table.insert(elements, { Foreground = { Color = segment_text_colors[i] } })
    table.insert(elements, { Background = { Color = gradient[i] } })
    table.insert(elements, { Text = ' ' .. seg .. ' ' })
  end

  window:set_right_status(wezterm.format(elements))
end)

-- Custom title and icon based on: https://github.com/protiumx/.dotfiles/blob/854d4b159a0a0512dc24cbc840af467ac84085f8/stow/wezterm/.config/wezterm/wezterm.lua#L291-L319
local process_icons = {
  ["bash"] = wezterm.nerdfonts.cod_terminal_bash,
  ["btm"] = wezterm.nerdfonts.mdi_chart_donut_variant,
  ["cargo"] = wezterm.nerdfonts.dev_rust,
  ["curl"] = wezterm.nerdfonts.mdi_flattr,
  ["docker"] = wezterm.nerdfonts.linux_docker,
  ["docker-compose"] = wezterm.nerdfonts.linux_docker,
  ["gh"] = wezterm.nerdfonts.dev_github_badge,
  ["git"] = wezterm.nerdfonts.fa_git,
  ["go"] = wezterm.nerdfonts.seti_go,
  ["htop"] = wezterm.nerdfonts.mdi_chart_donut_variant,
  ["kubectl"] = wezterm.nerdfonts.linux_docker,
  ["kuberlr"] = wezterm.nerdfonts.linux_docker,
  ["lazydocker"] = wezterm.nerdfonts.linux_docker,
  ["lazygit"] = wezterm.nerdfonts.oct_git_compare,
  ["lua"] = wezterm.nerdfonts.seti_lua,
  ["make"] = wezterm.nerdfonts.seti_makefile,
  ["node"] = wezterm.nerdfonts.mdi_hexagon,
  ["nvim"] = wezterm.nerdfonts.custom_vim,
  ["psql"] = "󱤢",
  ["ruby"] = wezterm.nerdfonts.cod_ruby,
  ["stern"] = wezterm.nerdfonts.linux_docker,
  ["sudo"] = wezterm.nerdfonts.fa_hashtag,
  ["usql"] = "󱤢",
  ["vim"] = wezterm.nerdfonts.dev_vim,
  ["wget"] = wezterm.nerdfonts.mdi_arrow_down_box,
  ["zsh"] = wezterm.nerdfonts.dev_terminal,
}

-- Return the Tab's current working directory
local function get_cwd(tab)
  return tab.active_pane.current_working_dir.file_path or ""
end

-- Remove all path components and return only the last value
local function remove_abs_path(path) return path:gsub("(.*[/\\])(.*)", "%2") end

-- Return the pretty path of the tab's current working directory
local function get_display_cwd(tab)
  local current_dir = get_cwd(tab)
  local HOME_DIR = string.format("file://%s", os.getenv("HOME"))
  return current_dir == HOME_DIR and "~/" or remove_abs_path(current_dir)
end

-- Return the concise name or icon of the running process for display
local function get_process(tab)
  if not tab.active_pane or tab.active_pane.foreground_process_name == "" then return "[?]" end

  local process_name = remove_abs_path(tab.active_pane.foreground_process_name)
  if process_name:find("kubectl") then process_name = "kubectl" end

  return process_icons[process_name] or string.format("[%s]", process_name)
end

-- Pretty format the tab title
local function format_title(tab)
  local cwd = get_display_cwd(tab)
  local process = get_process(tab)

  local active_title = tab.active_pane.title
  if active_title:find("- NVIM") then active_title = active_title:gsub("^([^ ]+) .*", "%1") end

  local description = (not active_title or active_title == cwd) and "~" or active_title
  return string.format(" %s %s/ %s ", process, cwd, description)
end

-- Determine if a tab has unseen output since last visited
local function has_unseen_output(tab)
  if not tab.is_active then
      for _, pane in ipairs(tab.panes) do
          if pane.has_unseen_output then return true end
      end
  end
  return false
end

-- Returns manually set title (from `tab:set_title()` or `wezterm cli set-tab-title`) or creates a new one
local function get_tab_title(tab)
  local title = tab.tab_title
  if title and #title > 0 then return title end
  return format_title(tab)
end

-- Convert arbitrary strings to a unique hex color value
-- Based on: https://stackoverflow.com/a/3426956/3219667
-- TODO: Reimplement this function to return colors from the catppuccin palette: https://catppuccin.com/palette
local function string_to_color(str)
  -- Convert the string to a unique integer
  local hash = 0
  for i = 1, #str do
      hash = string.byte(str, i) + ((hash << 5) - hash)
  end

  -- Convert the integer to a unique color
  local c = string.format("%06X", hash & 0x00FFFFFF)
  return "#" .. (string.rep("0", 6 - #c) .. c):upper()
end

local function select_contrasting_fg_color(hex_color)
  -- Note: this could use `return color:complement_ryb()` instead if you prefer or other builtins!

  local color = wezterm.color.parse(hex_color)
  ---@diagnostic disable-next-line: unused-local
  local lightness, _a, _b, _alpha = color:laba()
  if lightness > 55 then
      return "#000000" -- Black has higher contrast with colors perceived to be "bright"
  end
  return "#FFFFFF" -- White has higher contrast
end

-- Inline tests
local testColor = string_to_color("/Users/kyleking/Developer/ProjectA")
assert(testColor == "#EBD168", "Unexpected color value for test hash (" .. testColor .. ")")
assert(select_contrasting_fg_color("#494CED") == "#FFFFFF", "Expected higher contrast with white")
assert(select_contrasting_fg_color("#128b26") == "#FFFFFF", "Expected higher contrast with white")
assert(select_contrasting_fg_color("#58f5a6") == "#000000", "Expected higher contrast with black")
assert(select_contrasting_fg_color("#EBD168") == "#000000", "Expected higher contrast with black")

-- On format tab title events, override the default handling to return a custom title
-- Docs: https://wezfurlong.org/wezterm/config/lua/window-events/format-tab-title.html
---@diagnostic disable-next-line: unused-local
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = get_tab_title(tab)
  local color = string_to_color(get_cwd(tab))

  if tab.is_active then
      return {
          { Attribute = { Intensity = "Bold" } },
          { Background = { Color = color } },
          { Foreground = { Color = select_contrasting_fg_color(color) } },
          { Text = title },
      }
  end
  if has_unseen_output(tab) then
      return {
          { Foreground = { Color = "#C6A0F6" } },
          { Text = title },
      }
  end
  return title
end)

-- and finally, return the configuration to wezterm
return config

