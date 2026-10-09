# Claude Code の managed settings。
# ユーザー設定 (~/.claude/settings.json) より優先され、ユーザー権限では書き換えられないので、
# セキュリティ関係の設定はこちらに置く。
{ pkgs, ... }:
let
  managedSettings = name: value: {
    "claude-code/managed-settings.d/${name}.json".text = builtins.toJSON value;
  };

  # 複合コマンドの先頭で cd すると、その後の相対パスは実行してみるまで解決できないので、
  # blockReadsOutsideWorkingDirectories が毎回人間に確認を求めてくる。拒否理由をモデルに
  # 返して絶対パスで書き直させれば、確認は出ない。cd 単独のコマンドは通す。
  rejectCdCompound = pkgs.writeShellApplication {
    name = "claude-reject-cd-compound";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep ];
    text = ''
      command=$(jq -r '.tool_input.command // empty')
      lone_cd='^[[:space:]]*cd([[:space:]]+[^;&|]*)?[[:space:]]*$'
      if [[ $command != *$'\n'* && $command =~ $lone_cd ]]; then
        exit 0
      fi
      if printf '%s\n' "$command" | grep -Eq '(^|[;&|(])[[:space:]]*cd([[:space:]]|$)'; then
        echo "cd を含む複合コマンドは使わない。cd の後の相対パスは実行前に解決できず、読み取り制限の確認が人間に出る。cd を外して絶対パスで書くか、git -C などを使って書き直すこと。" >&2
        exit 2
      fi
    '';
  };
in
{
  # サンドボックスがプロキシの中継に使う。~ は denyRead で ~/.nix-profile の socat が
  # サンドボックス内から見えないため、システム側に置く。
  environment.systemPackages = [ pkgs.socat ];

  environment.etc =
    managedSettings "10-permissions"
      {
        permissions = {
          disableBypassPermissionsMode = "disable";
          blockReadsOutsideWorkingDirectories = true;
          deny = [
            "WebFetch"
            "WebSearch"
            "Edit"
            "Write"
            "NotebookEdit"
            "Read(./.env)"
          ];
        };
        allowManagedMcpServersOnly = true;
        allowedMcpServers = [ ];
      }
    // managedSettings "20-auto-mode" {
      autoMode = {
        classifyAllShell = true;
        environment = [ "$defaults" ];
        hard_deny = [ "$defaults" ];
      };
    }
    // managedSettings "30-sandbox" {
      sandbox = {
        enabled = true;
        failIfUnavailable = true;
        allowUnsandboxedCommands = false;
        excludedCommands = [ ];
        network = {
          allowedDomains = [ "github.com:443" "api.github.com:443" ];
          deniedDomains = [ "api.anthropic.com" "mcp-proxy.anthropic.com" ];
          strictAllowlist = true;
          allowManagedDomainsOnly = true;
          tlsTerminate = { };
        };
        filesystem = {
          denyWrite = [ "~/.claude" "~/.claude.json" ];
          denyRead = [ "/tmp" ];
          allowRead = [ "/tmp/claude-http-*.sock" "~/.config/git" ];
        };
        credentials.envVars = [
          {
            name = "GH_TOKEN";
            mode = "mask";
            injectHosts = [ "github.com" "api.github.com" ];
          }
        ];
      };
    }
    // managedSettings "40-hooks" {
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${rejectCdCompound}/bin/claude-reject-cd-compound";
            }
          ];
        }
      ];
    };
}
