-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
-- config.font = wezterm.font 'Hack Nerd Font Mono'
-- config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font = wezterm.font("0xProto Nerd Font Mono")
config.font_size = 13.0
-- For example, changing the color scheme:
config.color_scheme = "catppuccin-macchiato"

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.enable_scroll_bar = true

-- start with WSL
config.default_domain = "WSL:Ubuntu-22.04"

-- and finally, return the configuration to wezterm
return config

