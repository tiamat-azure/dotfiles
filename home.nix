{ config, pkgs, nixgl, system, pkgs-unstable, ... }:

let
  # Hors NixOS, wezterm ne trouve pas libEGL au runtime (pas de /run/opengl-driver).
  # On le fait passer par nixGL, qui injecte les bonnes libs Mesa/Intel.
  wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.packages.${system}.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';

  openwhispr = pkgs.callPackage ./pkgs/openwhispr.nix { };

  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Surveille le dossier Images et copie le chemin de chaque nouvelle capture
  # d'écran dans le presse-papier texte (les terminaux ne collent pas les
  # images du presse-papier, mais collent volontiers un chemin de fichier).
  screenshot-clip-watch = pkgs.writeShellScriptBin "screenshot-clip-watch" ''
    set -eu
    pictures_dir="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES)"
    ${pkgs.inotify-tools}/bin/inotifywait -m -r -e close_write --format '%w%f' "$pictures_dir" |
      while read -r file; do
        printf '%s' "$file" | ${pkgs.wl-clipboard}/bin/wl-copy
      done
  '';
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
    uv # python package/project manager
    rtk # proxy CLI qui compresse la sortie des commandes lues par les agents
    pkgs-unstable.herdr # absent du channel stable pinné, pris sur nixpkgs-unstable
    openwhispr
  ];

  # Icône dans le menu d'applications GNOME. pkgs.wezterm n'est pas dans
  # home.packages (collision avec le wrapper wezterm-gl sur bin/wezterm) :
  # on référence directement son icône, l'Exec passe par le wrapper nixGL.
  xdg.desktopEntries.wezterm = {
    name = "WezTerm";
    genericName = "Terminal Emulator";
    comment = "Wez's Terminal Emulator";
    icon = "${pkgs.wezterm}/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png";
    exec = "wezterm start --cwd .";
    terminal = false;
    categories = [ "System" "TerminalEmulator" "Utility" ];
    startupNotify = true;
    settings.StartupWMClass = "org.wezfurlong.wezterm";
  };
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.home-manager.enable = true;

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

        # nvm gère son propre installeur en ~/.nvm ; son script d'install ne peut
        # pas s'ajouter tout seul au .zshrc (symlink en lecture seule vers le Nix
        # store), donc on le source ici pour que node/npm soient dispo par défaut.
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      ''
    ];
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../../../";
      "...." = "cd ../../../../";

      myip = "curl http://ipecho.net/plain; echo"; # Show my ip address

      # handy short cuts #
      ll = "ls -lao";
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

      herdrw = "wezterm cli spawn --new-window -- herdr"; # herdr dans une nouvelle fenêtre WezTerm

      # Global Protect
      gpstop = "sudo systemctl stop gpd.service";
      gpstart = "sudo systemctl start gpd.service";
      gpstatus = "systemctl status gpd.service";

      # Herdr
      hreload = "herdr server reload-config";
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
  # Consignes d'usage de rtk, référencées depuis AGENTS.md via @RTK.md.
  # Régénérable avec `rtk init -g` (qui écrirait alors un fichier hors du repo).
  home.file.".claude/RTK.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/RTK.md";
  home.file.".claude/statusline-command.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline-command.sh";
  home.file.".agents/skills/git-commit-push".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/git-commit-push";
  home.file.".claude/skills/git-commit-push".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/git-commit-push";
  home.file.".agents/skills/memorise".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/memorise";
  home.file.".claude/skills/memorise".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/memorise";

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

    # Ajoute WINDOWS+SHIFT+S en plus de la touche Impr écran par défaut,
    # pour ouvrir l'outil de capture (sélection de zone) comme sous Windows.
    "org/gnome/shell/keybindings".show-screenshot-ui = [ "Print" "<Super><Shift>s" ];
  };

  systemd.user.services.screenshot-clip-watch = {
    Unit.Description = "Copie le chemin des nouvelles captures d'écran dans le presse-papier";
    Service.ExecStart = "${screenshot-clip-watch}/bin/screenshot-clip-watch";
    Service.Restart = "on-failure";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
