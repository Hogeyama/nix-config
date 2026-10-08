# Claude Code の managed settings。
# ユーザー設定 (~/.claude/settings.json) より優先され、ユーザー権限では書き換えられないので、
# セキュリティ関係の設定はこちらに置く。
{ pkgs, ... }:
let
  managedSettings = name: value: {
    "claude-code/managed-settings.d/${name}.json".text = builtins.toJSON value;
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
    };
}
