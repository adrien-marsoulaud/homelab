local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- Shell
config.default_prog = { '/usr/bin/zsh', '-l' }

-- Font
config.font = wezterm.font('FiraCode Nerd Font', { weight = 'Regular' })
config.font_size = 14.0
config.line_height = 1.2

-- Color scheme
config.color_scheme = 'Gruvbox Dark (Gogh)'

-- Scrollback
config.scrollback_lines = 10000

-- Active pane visibility
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.5,
}
config.colors = {
  split = '#444444',
}
config.window_frame = {
  active_titlebar_bg = '#1e1e2e',
}

-- Pane splitting
config.keys = {
  -- Split panes
  { key = 'o', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'e', mods = 'CTRL|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Navigate panes with ALT+hjkl
  { key = 'h',          mods = 'ALT', action = act.ActivatePaneDirection 'Left'  },
  { key = 'l',          mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'k',          mods = 'ALT', action = act.ActivatePaneDirection 'Up'    },
  { key = 'j',          mods = 'ALT', action = act.ActivatePaneDirection 'Down'  },
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left'  },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up'    },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down'  },

  -- Resize panes with ALT+SHIFT+hjkl
  { key = 'h', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left',  5 } },
  { key = 'l', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'k', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up',    5 } },
  { key = 'j', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down',  5 } },

  -- Zoom pane
  { key = 'x', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },

  -- Close pane
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
}

return config
