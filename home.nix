# https://rycee.gitlab.io/home-manager/options.html
{ config, pkgs, ... }:
let
  env = import ./env.nix;
in
{
  nixpkgs.config = {
    allowUnfree = true;
  };
  home = {
    packages = with pkgs; [
      awscli2
      aws-sam-cli
      bat
      bind
      curl
      deno
      docker
      docker-compose
      exa
      fd
      feh
      fuse
      gcc
      gh
      git-remote-codecommit
      gitflow
      go
      gopls
      golangci-lint
      google-cloud-sdk
      htop
      jq
      libreoffice
      lsof
      mercurial
      navi
      neovim-remote
      python3
      nodejs
      nodePackages.bash-language-server
      nodePackages.npm
      openssl
      pandoc
      ripgrep
      rnix-lsp
      shellcheck
      scrot
      sqlite
      textql
      time
      tldr
      unar
      ulauncher
      vifm
      wget
      yq
      zip
      # for firefox
      tridactyl-native
      ### font
      rounded-mgenplus
      illusion
      ### my packages
      my-xmobar
      my-fzf
      ### unstable
      unstable.alacritty
    ];
    file = {
      # neovim
      ".config/nvim/real-init.vim".source = ./files/.config/nvim/init.vim;
      ".config/nvim/coc-settings.json".source =
        (pkgs.formats.json { }).generate "coc-settings.json" {
          "suggest.keepCompleteopt" = true;
          "diagnostic.virtualText" = true;
          "diagnostic.virtualTextPrefix" = "-- ";
          "diagnostic.enableSign" = false;
          "coc.preferences.useQuickfixForLocations" = false;
          "coc.preferences.formatOnSaveFiletypes" = [
            "nix"
            "json"
            "javascript"
            "typescript"
            "typescriptreact"
            "haskell"
          ];
          "codeLens.enable" = true;
          "codeLens.position" = "eol";
          languageserver = {
            haskell = {
              command = "haskell-language-server-wrapper";
              args = [
                "--lsp"
                "-d"
                "-l"
                "/tmp/LanguageServer.log"
              ];
              rootPatterns = [
                "*.cabal"
                "stack.yaml"
                "cabal.project"
                "package.yaml"
                "hie.yaml"
              ];
              filetypes = [
                "haskell"
                "lhaskell"
              ];
              initializationOptions = {
                haskell = {
                  formattingProvider = "fourmolu";
                };
              };
            };
            ocaml = {
              command = "ocamllsp";
              args = [
                "--log-file"
                "/tmp/LanguageServer.log"
              ];
              filetypes = [
                "ocaml"
              ];
            };
            bash = {
              command = "bash-language-server";
              args = [
                "start"
              ];
              filetypes = [
                "sh"
              ];
            };
            nix = {
              command = "rnix-lsp";
              filetypes = [
                "nix"
              ];
            };
          };
          # coc-diagnostic
          "diagnostic-languageserver.filetypes" = {
            "sh" = "shellcheck";
            "bash" = "shellcheck";
          };
          # coc-yaml
          "yaml.customTags" = [
            "!Ref"
            "!Sub"
            "!ImportValue"
            "!GetAtt"
          ];
          # coc-java
          "java.configuration.runtimes" = [
            {
              "name" = "JavaSE-17";
              "path" = "${pkgs.openjdk17}/lib/openjdk";
            }
            {
              "name" = "JavaSE-11";
              "path" = "${pkgs.openjdk11}/lib/openjdk";
            }
            {
              "name" = "JavaSE-1.8";
              "path" = "${pkgs.openjdk8}/lib/openjdk";
              default = true;
            }
          ];
          "java.home" = "${pkgs.openjdk11}/lib/openjdk";
          "java.jdt.ls.vmargs" = "-Xms512m -Xmx512m -XX:+UseG1GC -XX:+UseStringDeduplication -javaagent:${pkgs.lombok}/share/java/lombok.jar";
          "java.signatureHelp.enabled" = true;
          "java.import.gradle.enabled" = true;
        };
      ".config/nvim/snippets" = {
        source = ./files/.config/nvim/snippets;
        recursive = true;
      };
      # vifm
      ".config/vifm/vifmrc".source = ./files/.config/vifm/vifmrc;
      ".config/vifm/colors/onedark.vifm".source = ./files/.config/vifm/colors/onedark.vifm;
      # navi
      ".local/share/navi/cheats" = {
        source = ./files/.local/share/navi/cheats;
        recursive = true;
      };
      # xmonad
      ".xmonad/xmonad-x86_64-linux".source = "${pkgs.my-xmonad}/bin/xmonad-x86_64-linux";
      ".xmonad/build" = {
        executable = true;
        text = ''echo "Nothing to do"'';
      };
      # firefox
      ".local/share/tridactyl/native_main".source = ./files/.local/share/tridactyl/native_main;
      ".config/tridactyl/tridactylrc".source = ./files/.config/tridactyl/tridactylrc;
      # alacritty
      ".config/alacritty.yml".source = ./files/.config/alacritty.yml;
      # my script
      #".local/bin/myfzf".source = ./files/.local/bin/myfzf;
      ".local/bin/myclip".source = ./files/.local/bin/myclip;
      ".local/bin/my-xmonad-borderwidth".source = ./files/.local/bin/my-xmonad-borderwidth;
      # wall paper
      "Pictures/reflexion.jpg".source = ./files/Pictures/reflexion.jpg;
    } // (if env.type == "nix-package-manager" then {
      # font
      ".config/fontconfig/conf.d/20-illusion-fonts.conf".source = ./files/.config/fontconfig/conf.d/20-illusion-fonts.conf;
    } else { });
    sessionVariables = {
      EDITOR = "nvim";
      JAVA_HOME = "${pkgs.openjdk11}/lib/openjdk";
      BROWSER = env.user.browser;
    };
  };
  programs = {
    home-manager = {
      enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = false;
    };
    fzf = {
      enable = true;
    };
    neovim = {
      enable = true;
      package = pkgs.unstable.neovim-unwrapped;
      withNodeJs = true;
      withPython3 = true;
      extraConfig = ''
        source  ~/.config/nvim/real-init.vim
      '';
    };
    tmux = {
      enable = true;
      terminal = "tmux-256color";
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.logging;
          extraConfig = ''
            # log
            set-option -g @logging_key "M-p"
            set-option -g @logging-path "$HOME/log/tmux"
            set-option -g @logging-filename "%Y%m%dT%H%M%S.log"
            # history
            set-option -g @save-complete-history-key "P"
            set-option -g @save-complete-history-path "$HOME/log/tmux"
            set-option -g @save-complete-history-filename "%Y%m%dT%H%M%S.history"
            set-option -g history-limit 100000
            # screen-capture
            set-option -g @screen-capture-key "M-Z"
          '';
        }
        {
          plugin = tmuxPlugins.jump;
        }
        {
          plugin = tmuxPlugins.nord;
        }
      ];
      extraConfig = ''
        ################################################################################
        # Basic
        ################################################################################

        # prefix=C-q
        set -g prefix C-q
        # Enable Italic
        set-option -g default-terminal "tmux-256color"
        # Enable True Color on xterm-256color
        set-option -ga terminal-overrides ",xterm-256color:Tc"
        # status bar on top
        set-option -g status-position top
        # no mouse
        set-option -g mouse off

        ################################################################################
        # Pane
        ################################################################################

        # vimのキーバインドでペインを移動する
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # vimのキーバインドでペインをリサイズする
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # | でペインを縦分割する
        bind | split-window -h

        # - でペインを縦分割する
        bind - split-window -v

        ################################################################################
        # Copy / Paste
        ################################################################################

        setw -g mode-keys vi

        bind C-q copy-mode

        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi V send -X select-line
        bind -T copy-mode-vi C-v send -X rectangle-toggle

        bind -T copy-mode-vi K send-keys -X -N 5 scroll-up
        bind -T copy-mode-vi J send-keys -X -N 5 scroll-down

        bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "myclip"
        bind -T copy-mode-vi y     send-keys -X copy-pipe-and-cancel "myclip"
      '';
    };
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      enableVteIntegration = true;
      autocd = true;
      history.extended = true;
      oh-my-zsh = {
        enable = true;
        theme = "frisk";
        plugins = [
          # [tool]
          "aws"
          "docker"
          "docker-compose"
          "fd"
          "fzf"
          "gcloud"
          "git"
          "git-auto-fetch"
          "gh"
          "ripgrep"
          "rsync"
          "ssh-agent"
          "zoxide"
          # [language]
          "cabal"
          "stack"
          "rust"
          "cargo"
          "node"
          "npm"
          "deno"
        ];
        extraConfig = ''
          # do not load any identities on start
          zstyle :omz:plugins:ssh-agent lazy yes
        '';
      };
      profileExtra = ''
        export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
      '';
      envExtra = ''
        source-if-exists() {
          [ -e $1 ] && . $1
        }
        test -z "''${ZSHENV_LOADED}" || return
        export ZSHENV_LOADED=1
        export PATH="$PATH:$HOME/.local/bin"
        source-if-exists "$HOME/.ghcup/env"
        source-if-exists "$HOME/.cargo/env"
        source-if-exists "$HOME/.opam/opam-init/init.zsh"
        source-if-exists "$HOME/.nix-profile/etc/profile.d/nix.sh"
        source-if-exists "$HOME/.autojump/etc/profile.d/autojump.sh"
        source-if-exists "$HOME/.poetry/env"
        source-if-exists "$HOME/.zshenv.local"
        export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export JAVA8_HOME=${pkgs.openjdk8}/lib/openjdk
        export JAVA11_HOME=${pkgs.openjdk11}/lib/openjdk
        export JAVA17_HOME=${pkgs.openjdk17}/lib/openjdk
        export JAVA_HOME="''$JAVA8_HOME"
      '';
      initExtra = ''
        eval "$(navi widget zsh)"
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' format '%B%d%b'
        zstyle ':completion:*:warnings' format 'No matches for: %d'
        # https://stackoverflow.com/questions/24226685
        zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        # drwxrwxrwxなるディレクトリ(other writable)が見にくいのを直す
        eval $(dircolors | sed 's/ow=[^:]*:/ow=01;34:/') #青背景白文字
        # bindkey
        bindkey "^K" up-line-or-history
        bindkey "^J" down-line-or-history
        bindkey "^I" expand-or-complete-prefix
        # functions
        cd-ls(){
          \cd $* && exa -s name
        }
        mkcd(){
          mkdir -p "$1" && cd "$1"
        }
        neovim(){
          if [[ -z "$NVIM_LISTEN_ADDRESS" ]]
          then
            nvim "$@"
          else
            nvr -p "$@"
          fi
        }
        ncd() {
          nvr -c "cd '$(realpath $1)'"
        }
        # source machine local configuration
        source-if-exists $HOME/.zshrc.local
      '';
      shellAliases = {
        ls = "exa -s name";
        cd = "cd-ls";
        mv = "mv -i";
        cp = "cp -iL";
        l = "ls -CF";
        ll = "ls -ahlF";
        la = "ls -A";
        DU = "du -hd1 | sort -h";
        open = "xdg-open";
        v = "neovim";
        vi = "neovim";
        vim = "neovim";
        gs = "git status";
      };
    };
    git = {
      enable = true;
      inherit (env.user.git) userName userEmail;
      extraConfig = {
        alias.stash-all = "stash save --include-untracked";
        core.autoCRLF = false;
        core.autoLF = false;
        fetch.prune = true;
        init.defaultBranch = "main";
        merge.ff = false;
        merge.conflictstyle = "diff3";
        merge.tool = "my-nvimdiff3";
        mergetool.my-nvimdiff3.cmd = "nvim -d -c 'wincmd J' $MERGED $LOCAL $BASE $REMOTE";
        pull.rebase = true;
        rebase.autoStash = true;
        rebase.autoSquash = true;
        rebase.missingCommitsCheck = "warn";
        rerere.enable = true;
        credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
      delta.enable = true;
    };
    zoxide = {
      enable = true;
    };
    gnome-terminal = {
      enable = false;
      showMenubar = false;
      profile = {
        test = {
          default = true;
          visibleName = "test";
          font = "Illusion N 13";
          allowBold = true;
          audibleBell = false;
          colors = {
            foregroundColor = "#cacacececdcd";
            backgroundColor = "#111112121313";
            boldColor = "#cacacececdcd";
            cursor = {
              foreground = "#111112121313";
              background = "#cacacececdcd";
            };
            palette = [
              "#323232323232"
              "#c2c228283232"
              "#8e8ec4c43d3d"
              "#e0e0c6c64f4f"
              "#4343a5a5d5d5"
              "#8b8b5757b5b5"
              "#8e8ec4c43d3d"
              "#eeeeeeeeeeee"
              "#323232323232"
              "#c2c228283232"
              "#8e8ec4c43d3d"
              "#e0e0c6c64f4f"
              "#4343a5a5d5d5"
              "#8b8b5757b5b5"
              "#8e8ec4c43d3d"
              "#ffffffffffff"
            ];

          };
        };
      };
    };
  };
  services.dropbox.enable = true;
}
# vim:foldmethod=indent:
