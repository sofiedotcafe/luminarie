{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.tmux;
in
{
  options.modules.home = {
    programs.tmux = {
      enable = mkEnableOption "tmux";
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      extraConfig = ''
        set -g mouse on
        set -g default-terminal "tmux-256color"

        set -g @catppuccin_window_status_style "rounded"

        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""

        set -g status-right "#{E:@catppuccin_status_application}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -agF status-right "#{E:@catppuccin_status_ram}"
        set -ag status-right "#{E:@catppuccin_status_session}"
        set -ag status-right "#{E:@catppuccin_status_uptime}"

        run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
      '';
    };
    catppuccin.vesktop.enable = config.catppuccin.enable;
  };
}
