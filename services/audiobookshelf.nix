{
  config,
  domain,
  mkProxy,
  ...
}:

{
  services.audiobookshelf.enable = true;

  services.nginx.virtualHosts."audiobookshelf.${domain}" =
    mkProxy config.services.audiobookshelf.port
    // {
      extraConfig = ''
        # Allow large file uploads
        client_max_body_size 10240M;
      '';
    };
}
