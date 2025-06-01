{ ... }:

{
  services.filebrowser = {
    enable = false;
    settings = {
      # Bind to the Tailscale IP address only so we can access it from Bifrost
      address = "100.69.0.42"; 
      port = 9090;
      root = "/mnt/storage";
    };
  };
}