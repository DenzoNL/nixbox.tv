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
    patchelf \
      --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
      --set-rpath "${cfg.stateDir}/game/bin/linuxsteamrt64" \
      ${cfg.stateDir}/game/bin/linuxsteamrt64/cs2
  '';

  steamCmdUpdate = ''
    steamcmd \
      +force_install_dir ${cfg.stateDir} \
      +login anonymous \
      +app_update 730 \
      +quit
  '';

  installMetamod = ''
    curl -L -o ${cfg.stateDir}/metamod.tar.gz https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1297-linux.tar.gz
    tar -xzf ${cfg.stateDir}/metamod.tar.gz -C ${cfg.stateDir}/game/csgo
    if ! grep -q 'Game csgo/addons/metamod' ${cfg.stateDir}/game/csgo/gameinfo.gi; then
      sed -i '/Game_LowViolence/a\                        Game csgo/addons/metamod' ${cfg.stateDir}/game/csgo/gameinfo.gi
    fi
  '';

  installCounterStrikeSharp = ''
    curl -L -o ${cfg.stateDir}/counterstrikesharp.zip https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v253/counterstrikesharp-build-253-linux-5644921.zip
    unzip -o ${cfg.stateDir}/counterstrikesharp.zip -d ${cfg.stateDir}/counterstrikesharp
    cp -r ${cfg.stateDir}/counterstrikesharp/addons ${cfg.stateDir}/game/csgo/
  '';

  installRockTheVote = ''
    curl -L -o ${cfg.stateDir}/rockthevote.zip https://github.com/abnerfs/cs2-rockthevote/releases/download/v1.8.5/RockTheVote_v1.8.5.zip
    unzip -o ${cfg.stateDir}/rockthevote.zip -d ${cfg.stateDir}/rockthevote
    cp -r ${cfg.stateDir}/rockthevote/RockTheVote ${cfg.stateDir}/game/csgo/addons/counterstrikesharp/plugins
  '';

  installMods = ''
    ${installMetamod}
    ${installCounterStrikeSharp}
    ${installRockTheVote}
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
    path = with pkgs; [ 
      curl
      gnugrep
      gnused
      gnutar
      gzip
      patchelf
      steamcmd
      unzip
    ];
    preStart = ''
      ${steamCmdUpdate}
      ${createSteamLink}
      ${patchElf}
      ${installMods}
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
