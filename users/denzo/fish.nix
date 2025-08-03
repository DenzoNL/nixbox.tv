{ ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAliases = {
      # Kubernetes aliases
      k = "kubectl";
      kc = "kubectx";
      kn = "kubens";
      tf = "terraform";
      
      # Modern replacements for ls
      ls = "exa --icons";
      ll = "exa -l --icons --git";
      la = "exa -la --icons --git";
      lt = "exa --tree --level=2 --icons";
      lta = "exa --tree --level=2 --icons --all";
    };
  };

  # Enable starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # Increase command timeout to prevent Java detection issues
      command_timeout = 1000;
      aws.disabled = true;
    };
  };
}