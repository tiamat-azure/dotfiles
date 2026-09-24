{ config, pkgs, lib, nixgl, system, pkgs-unstable, username, desktop, ... }:

let
  # Hors NixOS, wezterm ne trouve pas libEGL au runtime (pas de /run/opengl-driver).
  # On le fait passer par nixGL, qui injecte les bonnes libs Mesa/Intel.
  wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.packages.${system}.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';

  openwhispr = pkgs.callPackage ./pkgs/openwhispr.nix { };

  # sudo invoqué hors TTY (agent CLI, entrée .desktop, hook) ne peut pas demander
  # le mot de passe et échoue sur « a terminal is required to authenticate ».
  # SUDO_ASKPASS lui désigne ce helper, qui l'invite via une boîte de dialogue.
  # ssh-askpass n'est pas installé sur la machine, on passe par zenity.
  sudo-askpass = pkgs.writeShellScriptBin "sudo-askpass" ''
    exec ${pkgs.zenity}/bin/zenity --password --title="sudo"
  '';

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
  skills = [ "git-commit-push" "memorise" "init-agent" "design-showcase" ];
  skillLinks = lib.listToAttrs (lib.concatMap
    (skill: [
      (lib.nameValuePair ".agents/skills/${skill}" { source = link "home/.agents/skills/${skill}"; })
      (lib.nameValuePair ".claude/skills/${skill}" { source = link "home/.agents/skills/${skill}"; })
    ])
    skills);
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
    git-lfs # stockage des gros binaires hors du repo (assets Unity...), filtres dans ~/.config/git/config
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
    sudo-askpass # helper graphique de saisie du mot de passe sudo (voir SUDO_ASKPASS)
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
  home.sessionVariables = {
    EDITOR = "nvim";

    # Le réseau intercepte le TLS et resigne les certificats avec une CA racine
    # d'entreprise, présente dans le magasin système mais pas dans le magasin CA
    # embarqué de Node. curl passe (il lit NIX_SSL_CERT_FILE), Node échoue en
    # SELF_SIGNED_CERT_IN_CHAIN : les CLIs Node voient leurs appels HTTPS tomber en
    # « fetch failed » (constaté sur cursor.sh, grok.com et x.ai via quota-axi).
    # Node ne lit que NODE_EXTRA_CA_CERTS, on lui désigne donc le magasin système.
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
  } // lib.optionalAttrs desktop {
    # Suppose une session graphique : inutile (et zenity inutilement tiré dans la
    # closure) sous WSL. `sudo -A <cmd>` ouvre alors la fenêtre de saisie.
    SUDO_ASKPASS = "${sudo-askpass}/bin/sudo-askpass";
  };

  # ~/.local/bin : destination des installeurs maison hors Nix (Claude Code, Cursor CLI...).
  # Ubuntu ne l'ajoute au PATH que via ~/.profile, non lu par zsh : on le déclare ici pour
  # que ces binaires soient là quelle que soit la façon dont le shell est lancé. Placé avant
  # que .zshrc ne source nvm, donc node/npm restent servis par nvm et non par les shims.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;

  # Outils absents de nixpkgs, réinstallés à chaque switch pour rester reproductibles :
  # - gh-axi / chrome-devtools-axi / lavish-axi : CLIs "AXI" de kunchenguid utilisées par
  #   les hooks/skills Claude Code (voir home/.claude/settings.json et skills).
  # - @xai-official/grok : agent CLI xAI, fournit le binaire `grok`. Paquet officiel
  #   (mainteneur security@x.ai), préféré au `curl x.ai/cli/install.sh | bash` qui pose un
  #   binaire opaque hors de toute gestion de version.
  home.activation.installAgentTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Le PATH d'activation ne contient qu'une poignée de dérivations du store, sans
    # `awk` : nvm.sh se source alors sans erreur mais son auto-use échoue en silence
    # et node/npm n'atterrissent jamais dans le PATH (le bloc devenait un no-op).
    # On lui fournit donc ses dépendances explicitement.
    export PATH="${lib.makeBinPath [ pkgs.gawk pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.curl ]}:$PATH"
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      \. "$NVM_DIR/nvm.sh"
      if command -v npm >/dev/null; then
        # --prefix ~/.local plutôt que le préfixe global de nvm : celui-ci dépend de la
        # version node active, et elle diffère entre l'activation (PATH propre -> alias
        # `default`) et les shells de l'utilisateur (nvm conserve la version déjà
        # présente dans le PATH hérité de la session). Les binaires atterrissaient donc
        # dans un préfixe invisible depuis le terminal. ~/.local/bin est stable et déjà
        # déclaré dans home.sessionPath ; les shims npm trouvent node via leur shebang.
        $VERBOSE_ECHO "Installation des CLIs AXI (gh-axi, chrome-devtools-axi, lavish-axi) via npm"
        $DRY_RUN_CMD npm install -g --prefix "$HOME/.local" gh-axi chrome-devtools-axi lavish-axi
        $VERBOSE_ECHO "Installation de l'agent CLI Grok (@xai-official/grok) via npm"
        $DRY_RUN_CMD npm install -g --prefix "$HOME/.local" --allow-scripts=@xai-official/grok @xai-official/grok
      fi
    fi
  '';

  # Cursor CLI : pas de paquet npm officiel (`cursor-agent` sur npm appartient à un tiers),
  # seul l'installeur maison existe. Il pose une version figée dans
  # ~/.local/share/cursor-agent/versions/<v> et symlinke ~/.local/bin/{agent,cursor-agent}.
  # Contrairement à npm il re-télécharge ~100 Mo à chaque exécution : on ne le rejoue donc
  # pas à chaque switch, seulement si le binaire manque. Mise à jour : `agent update`.
  home.activation.installCursorAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # L'installeur suppose curl/tar/gzip présents : on les fournit depuis le store
    # plutôt que de dépendre de ce qu'Ubuntu expose dans le PATH d'activation.
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.gnutar pkgs.gzip pkgs.coreutils ]}:$PATH"
    if [ ! -e "$HOME/.local/bin/agent" ]; then
      $VERBOSE_ECHO "Installation de l'agent CLI Cursor (installeur cursor.com)"
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "curl -fsS https://cursor.com/install | ${pkgs.bash}/bin/bash"
    fi
  '';

  # Les éditeurs Unity récents (6000.6+) sont liés à libxml2.so.2, qu'Ubuntu 26.04 ne
  # fournit plus (seulement libxml2.so.16, ABI incompatible) : ils refusent de démarrer,
  # y compris depuis Unity Hub. Leur RUNPATH contient $ORIGIN, on dépose donc un lien
  # libxml2.so.2 à côté de chaque binaire Editor/Unity, pointant vers libxml2 2.13 du store.
  # Référencer le paquet ici le garde dans la closure de la génération (pas de GC), sans
  # l'ajouter à home.packages (son xmllint masquerait celui du système).
  # Un éditeur installé après le switch n'est couvert qu'au rebuild suivant.
  home.activation.unityLibxml2 = lib.mkIf desktop (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for editor in "$HOME"/Unity/Hub/Editor/*/Editor; do
      [ -x "$editor/Unity" ] || continue
      target="$editor/libxml2.so.2"
      # Ne jamais écraser un vrai fichier que Unity livrerait lui-même.
      if [ -e "$target" ] && [ ! -L "$target" ]; then continue; fi
      $VERBOSE_ECHO "Lien libxml2.so.2 pour $editor"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn ${pkgs.libxml2_13.out}/lib/libxml2.so.2 "$target"
    done
  '');

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
      # Applique la config puis recharge le shell courant, pour que les nouveaux
      # alias/fonctions soient dispo tout de suite (un script lancé en sous-process
      # ne peut pas modifier l'environnement du shell parent).
      rebuild = "~/.dotfiles/rebuild.sh && sourcez";

      # Redemarre la pile audio PipeWire/WirePlumber quand le son est muet
      # (WirePlumber sonde parfois la carte SOF avant que son firmware soit
      # pret au boot : plus aucun sink reel, seul un "Dummy Output" subsiste).
      fixsound = "systemctl --user restart wireplumber pipewire pipewire-pulse";

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
      quota = "quota-axi --provider claude,cursor,grok,copilot --tui";
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
      hud-start = "make -C ${config.home.homeDirectory}/workspaces/tiamat-azure/token-hud start";
      hud-stop = "make -C ${config.home.homeDirectory}/workspaces/tiamat-azure/token-hud stop";
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

    # Un seul AGENTS.md dans le repo, exposé sous le nom attendu par chaque agent.
    ".claude/CLAUDE.md".source = link "home/AGENTS.md";
    ".codex/AGENTS.md".source = link "home/AGENTS.md";
    ".config/opencode/AGENTS.md".source = link "home/AGENTS.md";
  } // skillLinks;

  # Équivalent déclaratif de `git lfs install` : filtres LFS dans le fichier de config
  # XDG de git, lu en plus de ~/.gitconfig (laissé non géré : identité, credentials).
  xdg.configFile."git/config".text = ''
    [filter "lfs"]
    	clean = git-lfs clean -- %f
    	smudge = git-lfs smudge -- %f
    	process = git-lfs filter-process
    	required = true
  '';

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
}
