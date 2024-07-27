{ config, pkgs, ... }:

let
  cfg = {
    stateDir = "/var/lib/cs2";
    hostname = "De Frietzaak";
    tickrate = 128;
    user = "cs2";
    group = "cs2";
    port = 27015;
  };

  createSteamLink = ''
    ln -sfv ${cfg.stateDir}/.steam/steam/linux64 ${cfg.stateDir}/.steam/sdk64
  '';

  patchElf = ''
    ${pkgs.patchelf}/bin/patchelf \
      --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
      --set-rpath "${cfg.stateDir}/game/bin/linuxsteamrt64" \
      ${cfg.stateDir}/game/bin/linuxsteamrt64/cs2
  '';

  steamCmdUpdate = ''
    ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir ${cfg.stateDir} \
      +login anonymous \
      +app_update 730 \
      +quit
  '';
in
{
  users.users.cs2 = {
    isSystemUser = true;
    home = cfg.stateDir;
    createHome = true;
    group = cfg.group;
  };

  users.groups.cs2 = {};

  networking.firewall.allowedTCPPorts = [ cfg.port ];
  networking.firewall.allowedUDPPorts = [ cfg.port ];

  sops.secrets."cs2/gslt" = {
    owner = cfg.user;
  };

  systemd.services.cs2 = {
    description = "Counter-Strike 2 Dedicated Server";
    wantedBy = [ "multi-user.target" ];
    environment = {
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        "${cfg.stateDir}/game/bin/linuxsteamrt64"
        "${pkgs.util-linux.lib}"
        "${pkgs.stdenv.cc.cc.lib}"
      ];
    };
    preStart = ''
      ${steamCmdUpdate}
      ${createSteamLink}
      ${patchElf}
    '';
    script = ''
      ${cfg.stateDir}/game/bin/linuxsteamrt64/cs2 \
        -dedicated \
        -port ${toString cfg.port} \
        -tickrate ${toString cfg.tickrate} \
        +map de_dust2 \
        +hostname ${cfg.hostname} \
        +sv_lan 0 \
        +sv_logfile 1 \
        +game_alias deathmatch \
        +sv_setsteamaccount $(cat ${config.sops.secrets."cs2/gslt".path})
    '';
    serviceConfig = {
      Type = "simple";
      TimeoutStartSec = 0;
      RestartSec = "120s";
      Restart = "always";
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = "${cfg.stateDir}";
    };
  };
}
