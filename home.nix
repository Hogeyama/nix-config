# https://rycee.gitlab.io/home-manager/options.html
{ config, pkgs, ... }:
let
  env = import ./env.nix;
  checkstyle = pkgs.writeScriptBin "checkstyle" ''
    #!${pkgs.stdenv.shell}
    set -eu
    JAVA=$JAVA_HOME/bin/java
    CHECKSTYLE=${pkgs.checkstyle}/checkstyle/checkstyle-all.jar

    ARGS=()

    # コンフィグファイル
    if [ -n "''${CHECKSTYLE_CONFIG_FILE:-}" ]; then
        ARGS+=("-c" "''${CHECKSTYLE_CONFIG_FILE}")
    else
        echo "CHECKSTYLE_CONFIG_FILE is not set" >&2
        exit 1
    fi

    # プロパティファイル
    PROPERTIES=$(mktemp)
    cat <<EOF >"$PROPERTIES"
    suppressions_xml = ''${CHECKSTYLE_SUPPRESSIONS_XML:-/dummy}
    config_loc       = ''${CHECKSTYLE_CONFIG_LOC:-/dummy}
    EOF
    ARGS+=("-p" "$PROPERTIES")

    # コマンドライン引数。null-ls.nvimが余計な引数を渡してくるため、`--`まで読み飛ばす
    while [[ $# -gt 0 ]]; do
        case $1 in
            --)
                shift
                break
                ;;
            *) ;;
        esac
        shift
    done
    ARGS+=("$@")

    "$JAVA" -jar $CHECKSTYLE "''${ARGS[@]}"
  '';
  xmonad = pkgs.symlinkJoin {
    name = "xmonad-x86_64-linux";
    paths = [ pkgs.my-xmonad ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/xmonad-x86_64-linux \
        --set BROWSER ${env.user.browser}
    '';
  };
in
{
  nixpkgs.config = {
    allowUnfree = true;
  };
  home = {
    packages = with pkgs; [
      albert
      aws2-wrap
      awscli2
      aws-sam-cli
      aws-vault
      bat
      bind
      cachix
      checkstyle
      comma
      commitizen
      curl
      deno
      docker
      docker-compose
      docker-credential-helpers
      exa
      fd
      feh
      fuse
      gcc
      gh
      gitflow
      git-remote-codecommit
      go
      golangci-lint
      google-cloud-sdk
      gopls
      gron
      hadolint
      hr
      htop
      jq
      just
      libreoffice
      lsof
      manix
      mercurial
      neovim-remote
      nix-du
      nix-tree
      nodejs
      nodePackages.bash-language-server
      nodePackages.npm
      nodePackages.prettier
      openssl
      pandoc
      pass
      pgcli
      pre-commit
      python310
      python310Packages.httpie
      ripgrep
      rnix-lsp
      scrot
      shellcheck
      shfmt
      simplescreenrecorder
      sqlite
      terraform
      textql
      time
      tldr
      ulauncher
      unar
      vifm
      watson
      wget
      yq
      zip
      # for firefox
      tridactyl-native
      ### font
      rounded-mgenplus
      illusion
      Cica
      ### my packages
      my-xmobar
      my-fzf
      my-fzf-wrapper
      ### unstable
      unstable.dasel
      unstable.alacritty
    ];
    file = {
      # neovim
      ".config/nvim/real-init.vim".source = ./files/.config/nvim/init.vim;
      ".config/nvim/lua/plugins.lua".source = ./files/.config/nvim/lua/plugins.lua;
      ".config/nvim/ftplugin" = {
        source = ./files/.config/nvim/ftplugin;
        recursive = true;
      };
      ".config/nvim/vsnip" = {
        source = ./files/.config/nvim/vsnip;
        recursive = true;
      };
      # direnv
      ".config/direnv/direnvrc".source = ./files/.config/direnv/direnvrc;
      ".config/direnv/direnv.toml".source = ./files/.config/direnv/direnv.toml;
      # albert
      ".config/albert/albert.conf".source = ./files/.config/albert/albert.conf;
      ".config/albert/org.albert.extension.websearch/engines.json".source = ./files/.config/albert/org.albert.extension.websearch/engines.json;
      ".local/share/albert/org.albert.extension.python/modules" = {
        source = ./files/.local/share/albert/org.albert.extension.python/modules;
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

      ".xmonad/xmonad-x86_64-linux".source = "${xmonad}/bin/xmonad-x86_64-linux";
      ".xmonad/build" = {
        executable = true;
        text = ''echo "Nothing to do"'';
      };
      # starship
      ".config/starship.toml".source = ./files/.config/starship.toml;
      # firefox
      ".local/share/tridactyl/native_main".source = ./files/.local/share/tridactyl/native_main;
      ".config/tridactyl/tridactylrc".source = ./files/.config/tridactyl/tridactylrc;
      # wezterm
      ".config/wezterm/wezterm.lua".source = ./files/.config/wezterm/wezterm.lua;
      # alacritty
      ".config/alacritty.yml".source = ./files/.config/alacritty.yml;
      # my script
      ".local/bin/myclip".source = ./files/.local/bin/myclip;
      ".local/bin/curlw".source = ./files/.local/bin/curlw;
      ".local/bin/jqw".source = ./files/.local/bin/jqw;
      ".local/bin/bttoggle".source = ./files/.local/bin/bttoggle;
      ".local/bin/vifm-preview".source = ./files/.local/bin/vifm-preview;
      ".local/bin/my-xmonad-borderwidth".source = ./files/.local/bin/my-xmonad-borderwidth;
      ".local/bin/haskell-language-server-wrapper-wrapper".source = ./files/.local/bin/haskell-language-server-wrapper-wrapper;
      # wall paper
      "Pictures/reflexion.jpg".source = ./files/Pictures/reflexion.jpg;
    } // (if env.type == "nix-package-manager" then {
      # font
      ".config/fontconfig/conf.d/20-illusion-fonts.conf".source = ./files/.config/fontconfig/conf.d/20-illusion-fonts.conf;
    } else { });
    sessionVariables = {
      EDITOR = ''bash -c 'nvim --server \"\''$NVIM\" --remote-tab-silent \"\''$@\"' --'';
      BROWSER = env.user.browser;

      AWS_PAGER = "";
      AWS_DEFAULT_OUTPUT = "yaml";
      AWS_CLI_AUTO_PROMPT = "on-partial";

      AWS_VAULT_BACKEND = "pass";
      AWS_VAULT_PASS_PREFIX = "aws-vault/";

      FZFW_FD_EXCLUDE_PATHS = ".git,.hg,.hie,dist-newstyle,__pycache__,Session.vim";

      # 典型的な実行ファイルはそのまま動くようにしておく。
      # NIX_LD_LIBRARY_PATH は必要そうなものを適宜足していく運用にする。
      # pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; の方が正しそうだが
      # access to canonical path is forbidden in restricted mode エラーが出るので妥協。
      NIX_LD = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";
      NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
        stdenv.cc.cc
        zlib
        ncurses
        gmp5
        openssl_1_1
      ];
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
      package = pkgs.neovim-nightly;
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
          extraConfig = ''
            set -g @jump-key 's'
          '';
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
          "node"
          "npm"
          "deno"
        ];
        extraConfig = ''
          # do not load any identities on start
          zstyle :omz:plugins:ssh-agent lazy yes
          # home-manager's module seems broken. Manually set fpath
          fpath+=(${pkgs.watson}/share/zsh/site-functions)
          fpath+=(${pkgs.just}/share/zsh/site-functions)
          fpath+=(${pkgs.pass}/share/zsh/site-functions)
          # dasel completion
          fpath+=(${pkgs.stdenv.mkDerivation {
            name = "dasel-completion";
            unpackPhase = "true";
            buildInputs = [ pkgs.unstable.dasel ];
            installPhase = ''
              mkdir -p $out/share/zsh/site-functions
              dasel --version
              dasel completion zsh > $out/share/zsh/site-functions/_dasel
            '';
          }}/share/zsh/site-functions)
          # for ddc-zsh
          zmodload zsh/zpty
        '';
      };
      envExtra = ''
        source-if-exists() {
          [ -e $1 ] && . $1
        }
        test -z "''${ZSHENV_LOADED}" || return
        export ZSHENV_LOADED=1
        export PATH="$HOME/.local/bin:$PATH" # prefer .local/bin
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
        export JAVA17_HOME=${pkgs.amazon-corretto17}
        export JAVA_HOME="''$JAVA17_HOME"
        export PATH="''$PATH:JAVA_HOME/bin"
      '';
      initExtra = ''
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
          if [[ -z "$NVIM_LISTEN_ADDRESS" ]] && [[ -z "$NVIM" ]]
          then
            nvim "$@"
          else
            nvr -p "$@"
          fi
        }
        ncd() {
          nvr -c "cd '$(realpath $1)'"
        }
        # なぜか fzf の completion がうまく動かないのでもう一度読む
        export FZF_COMPLETION_TRIGGER="::"
        . ${pkgs.fzf}/share/fzf/completion.zsh
        # source machine local configuration
        source-if-exists $HOME/.zshrc.local
      '';
      shellAliases = {
        ls = "exa -s name";
        cd = "cd-ls";
        mv = "mv -i";
        cp = "cp -iL";
        l = "ls -F";
        ll = "ls -ahlF";
        la = "ls -a";
        DU = "du -hd1 | sort -h";
        open = "xdg-open";
        v = "neovim";
        # vi = "neovim";
        # vim = "neovim";
        gs = "git status";
        glog = "git log --pretty=format:\"%C(yellow)%h%Creset %C(green)%ad%Creset %s %Cred%d%Creset %Cblue[%an]\" --date=short --graph";
        j = "just";
      };
    };
    git = {
      enable = true;
      inherit (env.user.git) userName userEmail;
      extraConfig = {
        alias.stash-all = "stash save --include-untracked";
        core.autoCRLF = false;
        core.autoLF = false;
        core.quotePath = false;
        fetch.prune = true;
        init.defaultBranch = "main";
        blame.date = "short";
        merge.ff = false;
        merge.conflictstyle = "diff3";
        merge.tool = "my-nvimdiff3";
        mergetool.my-nvimdiff3.cmd = "nvim -d -c 'wincmd J' $MERGED $LOCAL $BASE $REMOTE";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        rebase.missingCommitsCheck = "warn";
        rebase.abbreviateCommands = true;
        rerere.enabled = true;
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
    navi = {
      enable = true;
    };
    starship = {
      enable = true;
    };
    nix-index = {
      enable = true;
    };
  };
  services.dropbox.enable = true;
  manual.manpages.enable = false;
}
# vim:foldmethod=indent:
