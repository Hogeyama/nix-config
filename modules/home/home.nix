# https://nix-community.github.io/home-manager/options.xhtml
# https://mipmip.github.io/home-manager-option-search/
{ config, pkgs, self, env, ... }:
let
  dotfilesSymlinks =
    { rootDir ? "files"
    , clonedPath ? "${config.home.homeDirectory}/nix-config"
    }:
    let
      # /nix/store/.../files 以下を traverse して相対パスを取得する。
      # それを "${config.home.homeDirectory}/nix-config/${rootDir}" 以下の絶対パスに変換して、
      # $HOME 以下にシンボリックリンクを貼る。
      linksRootDirInStore = "${self}/${rootDir}";
      linksRootDirInVCS = "${clonedPath}/${rootDir}";
      toAbsPathInStore = s: "${linksRootDirInStore}/${s}";
      toAbsPathInVCS = s: "${linksRootDirInVCS}/${s}";
      dotfilesSymlinks' = dirPath:
        let
          # 相対パスの取得
          items = builtins.readDir (toAbsPathInStore dirPath);
          funcInner = name: type:
            let
              newDirPath = if dirPath == "" then name else "${dirPath}/${name}";
              fileOrSymlink =
                {
                  "${newDirPath}" = {
                    source = config.lib.file.mkOutOfStoreSymlink
                      (toAbsPathInVCS newDirPath);
                  };
                };
              cases = {
                "regular" = fileOrSymlink;
                "symlink" = fileOrSymlink;
                "directory" = dotfilesSymlinks' newDirPath;
              };
              otherwise = abort ("unknown item type: " + toAbsPathInVCS newDirPath);
            in
              cases.${type} or otherwise;
        in
        pkgs.lib.concatMapAttrs (name: type: funcInner name type) items;
    in
    dotfilesSymlinks' "";

  xmonad = pkgs.symlinkJoin {
    name = "xmonad-x86_64-linux";
    paths = [ pkgs.my-xmonad ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/xmonad-x86_64-linux \
        --set BROWSER  ${env.user.browser} \
        --set TERMINAL ${env.user.terminal}
    '';
  };

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

  nixDaemonS3CredentialsBin =
    pkgs.writeShellScriptBin "nix-daemon-s3-credentials" ''
      set -euo pipefail
      ACTION=''${1:-enable}
      AWS_SOURCE=~/.aws
      AWS_TARGET=/var/secrets/.aws

      if [ "$ACTION" = "enable" ]; then
        sudo mkdir -p "$AWS_TARGET"
        sudo ${pkgs.bindfs}/bin/bindfs -o ro \
          -g nixbld \
          -p g+rD \
          "$AWS_SOURCE" "$AWS_TARGET"
        sudo systemctl set-environment AWS_PROFILE="''${AWS_PROFILE:-default}"
        sudo systemctl set-environment AWS_SHARED_CREDENTIALS_FILE="$AWS_TARGET/credentials"
        sudo systemctl restart nix-daemon
        echo "Enabled nix-daemon S3 credentials..."
      else
        sudo umount "$AWS_TARGET"
        sudo systemctl unset-environment AWS_PROFILE AWS_SHARED_CREDENTIALS_FILE
        sudo systemctl restart nix-daemon
        echo "Disabled nix-daemon S3 credentials..."
      fi
    '';

  jnv = pkgs.fetchzip {
    name = "jnv-0.1.2";
    url = "https://github.com/ynqa/jnv/releases/download/v0.1.2/jnv-x86_64-unknown-linux-gnu.tar.xz";
    sha256 = "sha256-seooolfxOcC5RlFiK8RJY8dzVzxBFB+uzCF5k0O9ARY=";
    postFetch = ''
      install -Dm755 $out/jnv $out/bin/jnv
      rm -f $out/jnv
    '';
  };

in
{
  home = {
    stateVersion = "22.11";
    packages = with pkgs; [
      albert
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
      difftastic
      docker
      docker-compose
      docker-credential-helpers
      eslint_d
      eza
      fd
      feh
      fuse
      gcc
      gh
      gitflow
      git-remote-codecommit
      glow
      go
      golangci-lint
      google-cloud-sdk
      gopls
      gron
      hadolint
      hr
      htop
      jnv
      jq
      just
      libreoffice
      lsof
      manix
      maestral
      mercurial
      neovim-remote
      nix-du
      nix-tree
      nodejs
      nodePackages.bash-language-server
      nodePackages.mermaid-cli
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
      ### my packages
      my-xmobar
      my-fzf-wrapper
      ### unstable
      unstable.dasel
      nixDaemonS3CredentialsBin
    ];
    file = dotfilesSymlinks { } // {
      ".xmonad/xmonad-x86_64-linux".source = "${xmonad}/bin/xmonad-x86_64-linux";
      ".xmonad/build" = {
        executable = true;
        text = ''echo "Nothing to do"'';
      };
    };
    sessionVariables = {
      EDITOR = "nvimw";
      BROWSER = env.user.browser;

      # aws
      AWS_PAGER = "";
      AWS_DEFAULT_OUTPUT = "yaml";
      AWS_CLI_AUTO_PROMPT = "on-partial";

      # aws-vault
      AWS_VAULT_BACKEND = "pass";
      AWS_VAULT_PASS_PREFIX = "aws-vault/";

      # fzf
      FZF_TMUX = 1;
      FZF_TMUX_OPTS = "-p 80%";

      # direnv
      DIRENV_LOG_FORMAT = "";

      # my-fzf-wrapper
      FZFW_FD_EXCLUDE_PATHS = ".git,.hg,.hie,dist-newstyle,__pycache__,Session.vim,.direnv,node_modules,.next";

      # nix-ld
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
        icu
      ];
    };
  };
  programs = {
    home-manager = {
      enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      withNodeJs = true;
      withPython3 = true;
      extraPython3Packages = pyPkgs: with pyPkgs; [
        # for molten-nvim
        jupyter-client
        pyperclip
        nbformat
      ];
      extraLuaConfig = "\n" + ''
        -- config
        require("config.options")
        require("config.keymaps")
        require("config.commands")
        pcall(require, "config.local")

        -- plugins
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        if not vim.loop.fs_stat(lazypath) then
          vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath,
          })
        end
        vim.opt.rtp:prepend(lazypath)
        require("lazy").setup("plugins", {
          lockfile = vim.fn.getenv('HOME') .. "/nix-config/files/.config/nvim/lazy-lock.json",
        })
      '';
    };
    tmux = {
      enable = true;
      package = pkgs.tmux.overrideAttrs (oldAttrs: {
        # --enable-sixel is not available on 3.3a.
        version = "next-3.4";
        src = pkgs.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = "e809c2ec359b0fd6151cf33929244b7a7d637119";
          sha256 = "sha256-Ok9axRS15Ot+Z9VABF5fvuC2SSE1YNdIb1rBWZY6sNk=";
        };
        configureFlags = oldAttrs.configureFlags ++ [
          "--enable-sixel"
        ];
        patches = [ ];
      });
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
            # style
            set-option -g popup-border-style "fg=#c6c8d1,bg=#161821"
            set-option -g popup-border-lines "rounded"
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
          plugin = tmuxPlugins.power-theme;
          extraConfig = ''
            set -g @tmux_power_theme 'snow'
          '';
        }
        {
          plugin = tmuxPlugins.mkTmuxPlugin {
            pluginName = "tmux-timetrap";
            rtpFilePath = "timetrap.tmux";
            version = "v1";
            src = pkgs.fetchFromGitHub {
              owner = "croxarens";
              repo = "tmux-timetrap";
              rev = "8033567e626be876532c537e966ad8af2a27755b";
              sha256 = "sha256-DuZs0AIoNN5rThCp5lELEOpcG5Sl5VXYEscGu0IBrWc=";
            };
          };
          extraConfig = "";
        }
      ];
      escapeTime = 100;
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
    yazi.enable = true;
    xplr.enable = true;
    nushell = {
      enable = true;
      configFile.text = ''
        source ~/.config/nushell/local.nu
        $env.config = ($env | default {} config).config
        $env.config = ($env.config | upsert show_banner false)
      '';
      shellAliases = {
        ls = "eza -s name";
        cd = "cd-ls";
        mv = "mv -i";
        l = "ls -l";
        ll = "ls -al";
        la = "ls -a";
        # DU = "du -hd1 | sort -h";
        open = "xdg-open";
        v = "nvimw";
        gd = "git diff";
        gdn = "git diff --no-ext-diff";
        glog = ''git log --pretty=format:"%C(yellow)%h%Creset %C(green)%ad%Creset %s %Cred%d%Creset %Cblue[%an]" --date=short --graph'';
        rlog = ''git reflog --format="%C(yellow)%h%Creset %C(green)%gd%Creset %gs %Cred%d%Creset %Cblue[%an]" --date=iso-strict'';
        gmt = "git mergetool";
        gra = "git rebase --abort";
        grc = "git rebase --continue";
        grs = "git restore";
        gre = "git reset";
        gs = "git status --short --branch";
        gsh = "git show --ext-diff";
        gshn = "git show";
        gsw = "git switch -m";
        j = "just";
        da = "direnv allow";
        dr = "direnv reload";
        nb = "nix build";
        # awslocal = ''AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_DEFAULT_REGION=''${DEFAULT_REGION:-''${AWS_DEFAULT_REGION:-ap-northeast-1}} aws --endpoint-url=http://''${LOCALSTACK_HOST:-localhost.localstack.cloud}:4566'';
      };
      environmentVariables = {
        JAVA8_HOME = "${pkgs.openjdk8}/lib/openjdk";
        JAVA11_HOME = "${pkgs.openjdk11}/lib/openjdk";
        JAVA17_HOME = "${pkgs.openjdk17}/lib/openjdk";
        JAVA_HOME = "$env.JAVA17_HOME";
      };
    };
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableVteIntegration = true;
      syntaxHighlighting.enable = true;
      autocd = true;
      history.save = 1000000; # x100 of default
      history.size = 1000000; # x100 of default
      history.extended = true;
      history.ignoreSpace = false;

      oh-my-zsh = {
        enable = true;
        theme = "frisk";
        plugins = [
          # [tool]
          "docker"
          "fd"
          "git"
          "git-auto-fetch"
          "gh"
          "gradle"
          "ripgrep"
          "rsync"
          "ssh-agent"
          "zoxide"
          # [language]
          "cabal"
          "deno"
          "yarn"
        ];
        extraConfig = ''
          # do not load any identities on start
          zstyle :omz:plugins:ssh-agent lazy yes
        '';
      };
      envExtra = ''
        source-if-exists() {
          [ -e $1 ] && . $1
        }
        test -z "''${ZSHENV_LOADED}" || return
        export ZSHENV_LOADED=1
        export PATH="$HOME/.local/bin:$PATH" # prefer .local/bin
        export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export JAVA8_HOME=${pkgs.openjdk8}/lib/openjdk
        export JAVA11_HOME=${pkgs.openjdk11}/lib/openjdk
        export JAVA17_HOME=${pkgs.openjdk17}/lib/openjdk
        export JAVA_HOME="''$JAVA17_HOME"
        export PATH="''$PATH:''$JAVA_HOME/bin"
        source-if-exists "$HOME/.zshenv.local"
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
          \cd $* && eza -s name
        }
        mkcd(){
          mkdir -p "$1" && cd "$1"
        }
        ncd() {
          nvr -c "cd $(realpath $1)"
        }
        # source machine local configuration
        source-if-exists $HOME/.zshrc.local

        # tmux起動中はCtrl-Oでpopupを開いてコマンドラインを編集する
        if [[ -n "''$TMUX" ]]; then
            export VISUAL="nvimw --tmux-popup --light-mode --"
            autoload -Uz edit-command-line
            zle -N edit-command-line
            bindkey "^O" edit-command-line
        fi
      '';
      shellAliases = {
        ls = "eza -s name";
        cd = "cd-ls";
        mv = "mv -i";
        cp = "cp -iL";
        l = "ls -F";
        ll = "ls -ahlF";
        la = "ls -a";
        DU = "du -hd1 | sort -h";
        open = "xdg-open";
        v = "nvimw";
        gd = "git diff";
        gdn = "git diff --no-ext-diff";
        glog = ''git log --pretty=format:"%C(yellow)%h%Creset %C(green)%ad%Creset %s %Cred%d%Creset %Cblue[%an]" --date=short --graph'';
        rlog = ''git reflog --format="%C(yellow)%h%Creset %C(green)%gd%Creset %gs %Cred%d%Creset %Cblue[%an]" --date=iso-strict'';
        gmt = "git mergetool";
        gra = "git rebase --abort";
        grc = "git rebase --continue";
        grs = "git restore";
        gre = "git reset";
        gs = "git status --short --branch";
        gsh = "git show --ext-diff";
        gshn = "git show";
        gsw = "git switch -m";
        j = "just";
        da = "direnv allow";
        dr = "direnv reload";
        nb = "nix build";
        awslocal = ''AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_DEFAULT_REGION=''${DEFAULT_REGION:-''${AWS_DEFAULT_REGION:-ap-northeast-1}} aws --endpoint-url=http://''${LOCALSTACK_HOST:-localhost.localstack.cloud}:4566'';
      };
    };
    git = {
      enable = true;
      package = pkgs.git.overrideAttrs (oldAttrs: rec {
        version = "2.44.0";
        src = pkgs.fetchurl {
          url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
          hash = "sha256-41hzjctbXqNAzpAKABXAOuhugE5/9k5HqkYx3e5oHeM=";
        };
        preInstallCheck = oldAttrs.preInstallCheck + ''
          disable_test t9902-completion
        '';
      });
      extraConfig = {
        alias.stash-all = "stash save --include-untracked";
        alias.show-upstream = "git rev-parse --abbrev-ref --symbolic-full-name @{u}";
        blame.ignoreRevsFile = ".git-blame-ignore-revs";
        core.autoCRLF = false;
        core.autoLF = false;
        core.quotePath = false;
        blame.date = "short";
        branch.sort = "-committerdate";
        diff.external = "difft";
        diff.algorithm = "histogram";
        difftool.gron.cmd = ''diff --color -u <(gron "$LOCAL") <(gron "$REMOTE")'';
        fetch.prune = true;
        init.defaultBranch = "main";
        merge.ff = false;
        merge.conflictstyle = "zdiff3";
        merge.tool = "nvimdiff";
        mergetool.keepBackup = false;
        mergetool.vimdiff.layout = "(BASE,REMOTE)/(@LOCAL) + (REMOTE,LOCAL) + MERGED";
        mergetool.nvimdiff.layout = "(BASE,REMOTE)/(@LOCAL) + (REMOTE,LOCAL) + MERGED";
        mergetool.nvimdiff.trustExitCode = false;
        pull.rebase = true;
        push.autoSetupRemote = true;
        push.default = "current";
        rebase.autoStash = true;
        rebase.rebaseMerges = "rebase-cousins";
        rebase.updateRefs = true;
        rebase.missingCommitsCheck = "warn";
        rebase.abbreviateCommands = true;
        rerere.enabled = true;
        credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        include.path = "config.local";
      };
      delta.enable = true;
      delta.options = {
        side-by-side = false;
        line-numbers = false;
      };
    };
    zoxide = {
      enable = true;
    };
    vscode = {
      enable = true;
      package = (pkgs.vscode.override { isInsiders = false; }).overrideAttrs (oldAttrs: {
        src = (builtins.fetchTarball {
          url = "https://vscode.download.prss.microsoft.com/dbazure/download/stable/05047486b6df5eb8d44b2ecd70ea3bdf775fd937/code-stable-x64-1706696875.tar.gz";
          sha256 = "sha256:1r88dhqlk5f48bsnfhkc64pqxgwz5rqkf9rr2d3ip844364zlr9p";
        });
        buildInputs = oldAttrs.buildInputs ++ [ pkgs.libkrb5 ];
        version = "latest";
      });
    };
    navi = {
      enable = true;
    };
    starship = {
      enable = true;
    };
    rofi = {
      enable = true;
    };
    nix-index = {
      enable = true;
    };
  };
  services = {
    dropbox.enable = false;
    flameshot.enable = true;
  };
  systemd.user.services.maestral = {
    Unit.Description = "Maestral daemon";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.maestral}/bin/maestral start -f";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
      Nice = 10;
    };
  };
  manual.manpages.enable = false;
}
# vim:foldmethod=indent:
