{ config, pkgs, lib, nixgl, system, pkgs-unstable, username, desktop, ... }:

let
  # Hors NixOS, wezterm ne trouve pas libEGL au runtime (pas de /run/opengl-driver).
  # On le fait passer par nixGL, qui injecte les bonnes libs Mesa/Intel.
  wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.packages.${system}.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';

  openwhispr = pkgs.callPackage ./pkgs/openwhispr.nix { };

  # mdformat nu ne comprend pas le frontmatter YAML des SKILL.md (---\nname:...\n---) :
  # il l'aplatit comme un simple paragraphe. Le plugin mdformat-frontmatter lui apprend
  # à le laisser intact. mdformat-gfm lui apprend la syntaxe des tableaux GFM (sans lui,
  # un tableau pipe est traité comme du texte brut et cassé au reflow).
  mdformat-with-frontmatter = pkgs.python3.withPackages (ps: [
    ps.mdformat
    ps.mdformat-frontmatter
    ps.mdformat-gfm
  ]);

  # Interpréteur Python nommé à part (pas "python3", pour ne pas entrer en
  # collision avec le python3 par défaut du profil) exposant le module `gi`
  # (PyGObject) avec les typelibs Gdk/Gtk. Utilisé en shebang par les scripts
  # qui lisent l'écran via GDK, ex. my-autohotkey/linux/mouse_jiggler.py.
  # gtk3 fournit les .typelib (Gdk-3.0...) que pygobject3 seul n'inclut pas.
  python3-gi = pkgs.writeShellScriptBin "python3-gi" ''
    export GI_TYPELIB_PATH="${lib.makeSearchPath "lib/girepository-1.0" [
      pkgs.gtk3
      pkgs.gdk-pixbuf
      pkgs.pango.out
      pkgs.atk
      pkgs.cairo
      pkgs.harfbuzz
      pkgs.glib
      pkgs.gobject-introspection
    ]}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
    exec ${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 "$@"
  '';

  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  # Les skills vivent une seule fois dans le repo, mais chaque agent les cherche
  # dans son propre répertoire : ~/.agents/skills pour les agents génériques,
  # ~/.claude/skills pour Claude Code. D'où les deux liens par skill.
  skills = [ "git-commit-push" "memorise" "init-agent" ];
  skillLinks = lib.listToAttrs (lib.concatMap
    (skill: [
      (lib.nameValuePair ".agents/skills/${skill}" { source = link "home/.agents/skills/${skill}"; })
      (lib.nameValuePair ".claude/skills/${skill}" { source = link "home/.agents/skills/${skill}"; })
    ])
    skills);

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

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Ne change jamais cette valeur après la première install :
  # https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # cli i use constantly
    bat
    glow      # rendu markdown dans le terminal
    htop
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    perl      # utilisé par la fonction qwen pour réparer du JSON mal échappé
    lazygit
    neovim
    nerd-fonts.hack # the font everything renders in
    wl-clipboard # nvim's unnamedplus clipboard, needed on Wayland
    uv # python package/project manager
    rtk # proxy CLI qui compresse la sortie des commandes lues par les agents
    httpie # client HTTP en ligne de commande (https://httpie.io/docs/cli/universal)
    mdformat-with-frontmatter # reformate le markdown (reflow) sans casser le frontmatter YAML
    tokei # stats nombre de fichiers et LOC par type de fichier
    python3-gi # python3 + PyGObject, pour les scripts en shebang #!/usr/bin/env python3-gi
  ] ++ lib.optionals desktop [
    # Paquets GUI : GPU réel requis (nixGL) / session graphique. Hors WSL.
    wezterm-gl
    openwhispr
    pkgs-unstable.herdr # absent du channel stable pinné, pris sur nixpkgs-unstable
  ];

  # Icône dans le menu d'applications GNOME. pkgs.wezterm n'est pas dans
  # home.packages (collision avec le wrapper wezterm-gl sur bin/wezterm) :
  # on référence directement son icône, l'Exec passe par le wrapper nixGL.
  xdg.desktopEntries = lib.mkIf desktop {
    wezterm = {
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
  };
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.home-manager.enable = true;

  # Outils absents de nixpkgs, réinstallés à chaque switch pour rester reproductibles :
  # - gh-axi / chrome-devtools-axi / lavish-axi (npm, via nvm) : CLIs "AXI" de kunchenguid
  #   utilisées par les hooks/skills Claude Code (voir home/.claude/settings.json et skills).
  home.activation.installAgentTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      \. "$NVM_DIR/nvm.sh"
      if command -v npm >/dev/null; then
        $VERBOSE_ECHO "Installation des CLIs AXI (gh-axi, chrome-devtools-axi, lavish-axi) via npm"
        $DRY_RUN_CMD npm install -g gh-axi chrome-devtools-axi lavish-axi
      fi
    fi
  '';

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

        # ff : recherche récursive interactive par nom de fichier (fzf + preview bat),
        # ouvre le fichier choisi dans $EDITOR.
        ff() {
          local file
          file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers {}') || return
          ''${EDITOR:-nvim} "$file"
        }

        # fg : recherche récursive interactive par mot-clé dans le contenu des fichiers
        # (rg + fzf + preview bat avec la ligne surlignée), ouvre le résultat choisi
        # dans $EDITOR directement à la bonne ligne.
        fg() {
          # ne pas nommer une locale "path" : c'est un paramètre spécial zsh
          # lié au tableau $PATH, la déclarer localement le viderait.
          local match file_path lnum
          match=$(rg --line-number --hidden --glob '!.git' --color=always "''${1:-}" |
            fzf --ansi --delimiter : \
                --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
                --preview-window '+{2}-/2') || return
          file_path="''${match%%:*}"
          lnum="$(echo "$match" | cut -d: -f2)"
          ''${EDITOR:-nvim} "+$lnum" "$file_path"
        }

        # qwen : interroge l'agent LLM distant Telscale (API Ollama).
        # Voir home/AGENTS.md > "Agent distant Telscale (Ollama)".
        qwen() {
          local verbose=0
          if [ "$1" = "-v" ]; then
            verbose=1
            shift
          fi
          local resp
          resp="$(http POST https://tiamat-wsl.tail9a63d9.ts.net/api/chat \
            model=qwen3:14b stream:=false \
            messages:="[{\"role\":\"user\",\"content\":$(jq -Rn --arg m "$*" '$m')}]")"
          if [ "$verbose" = 1 ]; then
            echo "$resp"
          else
            # Le serveur renvoie parfois du JSON invalide (retours à la ligne
            # bruts au lieu de \n échappés dans .message.content) : on les
            # ré-échappe avant de parser, sinon jq échoue.
            local content
            content="$(printf '%s' "$resp" |
              perl -0pe 's/\r\n/\n/g; s/\n/\\n/g; s/\t/\\t/g' |
              jq -r '.message.content' 2>/dev/null)"
            if [ -n "$content" ]; then
              printf '%s' "$content" | glow -
            else
              echo "Réponse illisible, affichage brut :" >&2
              echo "$resp"
            fi
          fi
        }

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

      sourcez = "source ~/.zshrc";

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
      cc = ''claude --dangerously-skip-permissions --system-prompt "Tu es un assistant de code concis et précis."'';
      co = "codex --full-auto";
      copilot = "copilot --yolo";
      cclog = "~/.claude/scripts/show-session-log.sh";
      ccstats = "~/.claude/scripts/claude-usage-stats.sh";
      ccstats-readme = "~/.claude/scripts/update-readme-stats.sh ~/.dotfiles/README.md";
    } // lib.optionalAttrs desktop {
      # Dépendent de WezTerm, herdr ou du VPN de la machine desktop : hors WSL.
      herdrw = "wezterm cli spawn --new-window -- herdr"; # herdr dans une nouvelle fenêtre WezTerm

      # Global Protect
      gpstop = "sudo systemctl stop gpd.service";
      gpstart = "sudo systemctl start gpd.service";
      gpstatus = "systemctl status gpd.service";

      # Herdr
      hreload = "herdr server reload-config";

      # token-hud : widget PyQt6, lancé détaché pour rendre le terminal.
      hud-start = "nohup uv run --project ${config.home.homeDirectory}/workspaces/tiamat-azure/token-hud python -m token_hud >/dev/null 2>&1 &";
      hud-stop = "pkill -f 'python -m token_hud'";
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
  home.file = {
    ".config/wezterm".source = link "home/.config/wezterm";
    ".config/nvim".source = link "home/.config/nvim";
    ".config/herdr".source = link "home/.config/herdr";
    ".claude/settings.json".source = link "home/.claude/settings.json";
    # Consignes d'usage de rtk, référencées depuis AGENTS.md via @RTK.md.
    # Régénérable avec `rtk init -g` (qui écrirait alors un fichier hors du repo).
    ".claude/RTK.md".source = link "home/.claude/RTK.md";
    # Dépannage rtk : volontairement pas importé via @, seulement référencé par
    # chemin depuis RTK.md, pour rester hors du contexte injecté à chaque session.
    ".claude/rtk-troubleshooting.md".source = link "home/.claude/rtk-troubleshooting.md";
    ".claude/statusline-command.sh".source = link "home/.claude/statusline-command.sh";
    ".claude/hooks/mdformat-on-edit.sh".source = link "home/.claude/hooks/mdformat-on-edit.sh";
    ".claude/scripts/show-session-log.sh".source = link "home/.claude/scripts/show-session-log.sh";
    ".claude/scripts/claude-usage-stats.sh".source = link "home/.claude/scripts/claude-usage-stats.sh";
    ".claude/scripts/update-readme-stats.sh".source = link "home/.claude/scripts/update-readme-stats.sh";

    # Un seul AGENTS.md dans le repo, exposé sous le nom attendu par chaque agent.
    ".claude/CLAUDE.md".source = link "home/AGENTS.md";
    ".codex/AGENTS.md".source = link "home/AGENTS.md";
    ".config/opencode/AGENTS.md".source = link "home/AGENTS.md";
  } // skillLinks;

  # Équivalent GNOME des system.defaults de nix-darwin (dark mode, dock, trackpad...).
  # Réservé aux machines desktop : pas de session GNOME/dbus sous WSL.
  dconf.settings = lib.mkIf desktop {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";

    "org/gnome/desktop/peripherals/keyboard" = {
      repeat-interval = 20; # répétition rapide (ms)
      delay = 200;          # délai avant répétition (ms)
    };

    "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;

    # Autorise SUPER + clic-droit pour redimensionner une fenêtre (utile pour
    # WezTerm, sans barre de titre, dont window_decorations = "NONE" masque
    # les poignées de redimensionnement natives).
    "org/gnome/desktop/wm/preferences".resize-with-right-button = true;

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false; # nécessaire pour l'auto-hide
      autohide = true;
    };

    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";

    # Ajoute WINDOWS+SHIFT+S en plus de la touche Impr écran par défaut,
    # pour ouvrir l'outil de capture (sélection de zone) comme sous Windows.
    "org/gnome/shell/keybindings".show-screenshot-ui = [ "Print" "<Super><Shift>s" ];
  };

  systemd.user.services.screenshot-clip-watch = lib.mkIf desktop {
    Unit.Description = "Copie le chemin des nouvelles captures d'écran dans le presse-papier";
    Service.ExecStart = "${screenshot-clip-watch}/bin/screenshot-clip-watch";
    Service.Restart = "on-failure";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
