{vscode-server.nixosModule
({ config, pkgs, ... }: {
  services.vscode-server.enable = true;
})}
}