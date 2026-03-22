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
        # Anthropic / Claude
        "api.anthropic.com"
        "statsig.anthropic.com"
        "platform.claude.com"
        "mcp-proxy.anthropic.com"
        "code.claude.com"
        "claude.ai"

        # OpenAI / ChatGPT
        "api.openai.com"
        "*.api.openai.com"
        "ab.chatgpt.com"
        "chatgpt.com"

        # Google
        "storage.googleapis.com"

        # GitHub
        "api.github.com"
        # ユーザーのやつ
        "github.com"
        "gist.github.com"
        "raw.githubusercontent.com"
        "release-assets.githubusercontent.com"
        # Copilot
        "api.githubcopilot.com"
        "telemetry.individual.githubcopilot.com"
        "api.individual.githubcopilot.com"
        "telemetry.business.githubcopilot.com"
        "api.business.githubcopilot.com"
        # 画像系
        "camo.githubusercontent.com"
        "avatars.githubusercontent.com"

        # Docker Hub
        "registry-1.docker.io"
        "auth.docker.io"
        "index.docker.io"
        "hub.docker.com"
        "www.docker.com"
        "production.cloudflare.docker.com"
        "download.docker.com"

        # Container Registries
        "*.gcr.io" # Google Container Registry
        "ghcr.io" # GitHub Container Registry
        "mcr.microsoft.com" # Microsoft Container Registry
        "*.data.mcr.microsoft.com"
        "public.ecr.aws" # AWS ECR

        # Package Registries
        # npm
        "registry.npmjs.org"
        # deno
        "jsr.io" # JSR (Deno)
        "deno.land" # Deno
        # Rust
        "index.crates.io"
        "static.crates.io"

        # IETF Datatracker
        "datatracker.ietf.org"
      ];
      prompt = {
        enable = true;
        denylist = [
          # Claude Codeがなんか送ってるやつ
          "http-intake.logs.us5.datadoghq.com"
        ];
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
