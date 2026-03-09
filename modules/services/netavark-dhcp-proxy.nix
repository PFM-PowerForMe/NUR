{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.pfm.services.netavark-dhcp-proxy;
in
{
  options.pfm.services.netavark-dhcp-proxy = {
    enable = lib.mkEnableOption "Podman DHCP服务";
  };

  config = lib.mkIf cfg.enable {

    systemd.services.netavark-dhcp-proxy = {
      description = "Netavark DHCP proxy";
      serviceConfig = {
        ExecStart = "${pkgs.pfm.podman}/libexec/podman/netavark dhcp-proxy";
        Restart = "on-failure";
        Type = "simple";
      };
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.sockets.netavark-dhcp-proxy = {
      description = "Netavark DHCP proxy socket";
      listenStreams = [ "/run/podman/nv-proxy.sock" ];
      socketConfig = {
        RuntimeDirectory = "podman";
        SocketMode = "0600";
        User = "root";
        Group = "users";
      };
      wantedBy = [ "sockets.target" ];
    };

  };
}
