{ ... }:

{
  services.wyoming.faster-whisper.servers."home-assistant" = {
    enable = true;
    language = "nl";
    model = "small-int8";
    uri = "tcp://0.0.0.0:10300";
  };

  # services.wyoming.piper.servers."home-assistant" = {
  #   enable = true;
  #   voice = "nl_BE-rdh-medium";
  #   uri = "tcp://0.0.0.0:10200";
  # };
}