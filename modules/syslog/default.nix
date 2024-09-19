{ ... }:
{
  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      include(file="/etc/rsyslog/conf.d/*.conf" mode="optional")
    '';
  };
}
