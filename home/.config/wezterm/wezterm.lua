local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Terminal
config.default_prog = { "/usr/bin/zsh", "-l" }

-- Apparence
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "NONE"
config.enable_wayland = false

-- Mode multiplexeur persistant
config.key_tables = {
  multiplex = {
    -- Splits
    {
      key = "d",
      action = act.SplitHorizontal({
        domain = "CurrentPaneDomain",
      }),
    },
    {
      key = "s",
      action = act.SplitVertical({
        domain = "CurrentPaneDomain",
      }),
    },

    -- Navigation
    {
      key = "LeftArrow",
      action = act.ActivatePaneDirection("Left"),
    },
    {
      key = "RightArrow",
      action = act.ActivatePaneDirection("Right"),
    },
    {
      key = "UpArrow",
      action = act.ActivatePaneDirection("Up"),
    },
    {
      key = "DownArrow",
      action = act.ActivatePaneDirection("Down"),
    },

    -- Resize
    {
      key = "LeftArrow",
      mods = "SHIFT",
      action = act.AdjustPaneSize({ "Left", 3 }),
    },
    {
      key = "RightArrow",
      mods = "SHIFT",
      action = act.AdjustPaneSize({ "Right", 3 }),
    },
    {
      key = "UpArrow",
      mods = "SHIFT",
      action = act.AdjustPaneSize({ "Up", 3 }),
    },
    {
      key = "DownArrow",
      mods = "SHIFT",
      action = act.AdjustPaneSize({ "Down", 3 }),
    },

    -- Panneaux
    {
      key = "z",
      action = act.TogglePaneZoomState,
    },
    {
      key = "w",
      action = act.CloseCurrentPane({
        confirm = true,
      }),
    },

    -- Onglets
    {
      key = "c",
      action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
      key = "x",
      action = act.CloseCurrentTab({
        confirm = true,
      }),
    },

    -- Sortie mode multiplex
    {
      key = "Escape",
      action = act.PopKeyTable,
    },
  },
}

-- Raccourcis globaux
config.keys = {
  {
    key = "Space",
    mods = "CTRL",
    action = act.ActivateKeyTable({
      name = "multiplex",
      one_shot = false,
    }),
  },
  {
    key = "r",
    mods = "CTRL|SHIFT",
    action = act.ReloadConfiguration,
  },
}

-- Souris
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Middle" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

return config


