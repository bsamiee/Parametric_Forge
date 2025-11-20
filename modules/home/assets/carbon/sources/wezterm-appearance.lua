-- WezTerm appearance (Dracula + GeistMono)
local wezterm = require 'wezterm'

return function(config)
  config.color_scheme = 'Dracula'
  config.font = wezterm.font_with_fallback {
    { family = 'GeistMono Nerd Font', weight = 'Regular' },
    { family = 'Geist Mono', weight = 'Regular' },
    { family = 'Fira Code', weight = 'Regular' },
  }
  config.window_decorations = 'RESIZE'
  config.window_background_opacity = 0.94
  config.colors = {
    cursor_bg = '#94F2E8',
    cursor_border = '#94F2E8',
    cursor_fg = '#15131F',
    tab_bar = {
      background = '#1D1A29',
      active_tab = { bg_color = '#2A2640', fg_color = '#F8F8F2', intensity = 'Bold' },
      inactive_tab = { bg_color = '#1D1A29', fg_color = '#6272A4' },
    },
  }
end
