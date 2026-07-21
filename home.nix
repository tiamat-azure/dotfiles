{ config, pkgs, nixgl, system, ... }:

let
  # Hors NixOS, wezterm ne trouve pas libEGL au runtime (pas de /run/opengl-driver).
  # On le fait passer par nixGL, qui injecte les bonnes libs Mesa/Intel.
  wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.packages.${system}.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';

  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  nixpkgs.config.allowUnfree = true;

  home.username = "2456bru";
  home.homeDirectory = "/home/2456bru";

  # Ne change jamais cette valeur après la première install :
  # https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # cli i use constantly
    bat
    htop
    wezterm-gl
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    nerd-fonts.hack # the font everything renders in
    wl-clipboard # nvim's unnamedplus clipboard, needed on Wayland
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.home-manager.enable = true;

  xdg.desktopEntries.wezterm = {
    name = "WezTerm";
    genericName = "Terminal Emulator";
    comment = "GPU-accelerated terminal emulator";
    exec = "wezterm";
    icon = "org.wezfurlong.wezterm";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "org.wezfurlong.wezterm";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = pkgs.lib.mkMerge [
      # Doit s'exécuter avant que le plugin zsh-autosuggestions ne soit sourcé (ordre 700)
      # pour que expand-or-complete (Tab) soit repris dans le mécanisme d'acceptation :
      # suggestion présente -> accepte puis complète ; sinon -> complétion normale inchangée.
      (pkgs.lib.mkOrder 690 ''
        ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(expand-or-complete)
      '')
      ''
        mkcd() { mkdir -p "$1" && cd "$1"; }
      ''
    ];
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../../../";
      "...." = "cd ../../../../";

      myip = "curl http://ipecho.net/plain; echo"; # Show my ip address

      # handy short cuts #
      ll = "ls -la";
      c = "clear";
      h = "history";
      hs = "history | grep";
      j = "jobs -l";

      # Stop after sending count ECHO_REQUEST packets #
      ping = "ping -c 5";

      ## Date and Time Aliases
      d = ''date +"%F"'';
      now = ''date +"%F %T"'';

      status = "git status";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/statusline-command.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline-command.sh";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";

  # Équivalent GNOME des system.defaults de nix-darwin (dark mode, dock, trackpad...).
  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";

    "org/gnome/desktop/peripherals/keyboard" = {
      repeat-interval = 20; # répétition rapide (ms)
      delay = 200;          # délai avant répétition (ms)
    };

    "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false; # nécessaire pour l'auto-hide
      autohide = true;
    };

    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
  };
}
