{ config, pkgs, ... }:

{
  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # nouveau open source driver).
    # This is available on RTX 20 series and newer CPUs.
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # STUB: Revisit if GPU is older than Maxwell (GTX 900 series). 
    # For very old cards, use config.boot.kernelPackages.nvidiaPackages.legacy_XXX
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Graphics settings
  hardware.graphics = {
    enable = true;
  };
}
