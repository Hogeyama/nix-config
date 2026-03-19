let
  common_infra = {
    nix = {
      enable = "auto";
      mount-socket = true;
    };
    docker = {
      enable = true;
      shared = true;
    };
    extra-mounts = [
      {
        # gitignoreが居る
        src = "~/nix-config";
        dst = "~/nix-config";
        mode = "ro";
      }
    ];
  };

  common_network = {
    network = {
      allowlist = [
        "api.anthropic.com"
        "statsig.anthropic.com"
        "platform.claude.com"
        "storage.googleapis.com"
        "mcp-proxy.anthropic.com"
        "http-intake.logs.us5.datadoghq.com"
        "code.claude.com"
        "release-assets.githubusercontent.com"
        "claude.ai"
        "api.openai.com"
        "ab.chatgpt.com"
        "chatgpt.com"
        "*.api.openai.com"
        "github.com"
        "docs.github.com"
        "www.github.com"
        "api.github.com"
        "api.githubcopilot.com"
        "api.individual.githubcopilot.com"
        "api.business.githubcopilot.com"
        "telemetry.individual.githubcopilot.com"
        "telemetry.business.githubcopilot.com"
        "npm.pkg.github.com"
        "raw.githubusercontent.com"
        "pkg-npm.githubusercontent.com"
        "objects.githubusercontent.com"
        "codeload.github.com"
        "avatars.githubusercontent.com"
        "camo.githubusercontent.com"
        "gist.github.com"
        "gitlab.com"
        "www.gitlab.com"
        "registry.gitlab.com"
        "bitbucket.org"
        "www.bitbucket.org"
        "api.bitbucket.org"
        "registry-1.docker.io"
        "auth.docker.io"
        "index.docker.io"
        "hub.docker.com"
        "www.docker.com"
        "production.cloudflare.docker.com"
        "download.docker.com"
        "gcr.io"
        "*.gcr.io"
        "ghcr.io"
        "mcr.microsoft.com"
        "*.data.mcr.microsoft.com"
        "public.ecr.aws"
        "oidc.ap-northeast-1.amazonaws.com"
        "registry.npmjs.org"
        "jsr.io"
        "deno.land"
        "index.crates.io"
        "static.crates.io"
        "datatracker.ietf.org"
      ];
      prompt = {
        enable = true;
      };
    };
  };

  common_env = {
    env = [
      { key = "TZ"; val = "Asia/Tokyo"; }
      { key = "LANG"; val = "en_US.UTF-8"; }
      # hostexecのgpgで署名する
      { key = "GIT_CONFIG_COUNT"; val = "1"; }
      { key = "GIT_CONFIG_KEY_0"; val = "gpg.program"; }
      { key = "GIT_CONFIG_VALUE_0"; val = "gpg"; }
    ];
  };

  common_hostexec = {
    hostexec = {
      prompt = {
        enable = true;
        timeout-seconds = 300;
        default-scope = "capability";
      };
      rules = [
        {
          id = "git-fetch-pull";
          match = {
            argv0 = "git";
            arg-regex = ''^(fetch|pull)\b'';
          };
          cwd = {
            mode = "workspace-or-session-tmp";
          };
          approval = "allow";
          fallback = "container";
        }
        {
          id = "gh";
          match = {
            argv0 = "gh";
          };
          cwd = {
            mode = "workspace-or-session-tmp";
          };
          approval = "allow";
          fallback = "container";
        }
        {
          id = "gpg-sign";
          match = {
            argv0 = "gpg";
            arg-regex = ''(^|\s)(--sign|-[a-zA-Z]*s[a-zA-Z]*)(\s|$)'';
          };
          cwd = {
            mode = "workspace-or-session-tmp";
          };
          approval = "allow";
          fallback = "container";
        }
      ];
    };
  };

  mkProfile = builtins.foldl' (acc: overlay: acc // overlay) { };
in
{
  default = "claude";

  profiles = {
    claude = mkProfile [
      { agent = "claude"; }
      { agent-args = [ "--dangerously-skip-permissions" ]; }
      {
        env = common_env.env ++ [
          # 認証
          { key = "CLAUDE_CODE_OAUTH_TOKEN"; val_cmd = "pass claude_code_oauth_token"; }
        ];
      }
      common_infra
      common_network
      common_hostexec
    ];

    codex = mkProfile [
      { agent = "codex"; }
      {
        agent-args = [
          "--dangerously-bypass-approvals-and-sandbox"
        ];
      }
      {
        dbus = {
          session = {
            enable = true;
            calls = [
              {
                name = "org.freedesktop.secrets";
                rule = "org.freedesktop.Secret.Service.OpenSession";
              }
              {
                name = "org.freedesktop.secrets";
                rule = "org.freedesktop.Secret.Service.SearchItems";
              }
              {
                name = "org.freedesktop.secrets";
                rule = "org.freedesktop.Secret.Item.GetSecret";
              }
            ];
          };
        };
      }
      common_env
      common_infra
      common_network
      common_hostexec
    ];

    copilot = mkProfile [
      { agent = "copilot"; }
      {
        agent-args = [
          "--allow-all"
        ];
      }
      {
        extra-mounts = [
          {
            # gitignoreが居る
            src = "~/nix-config";
            dst = "~/nix-config";
            mode = "ro";
          }
        ];
      }
      common_env
      common_infra
      common_network
      common_hostexec
    ];
  };
}
