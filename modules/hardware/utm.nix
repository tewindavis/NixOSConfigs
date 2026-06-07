{ pkgs, ... }:

{
  # UTM/QEMU Guest support
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true; # Enables clipboard and resolution scaling
  
  environment.systemPackages = [ pkgs.wl-clipboard ];

  # Ensure the VirtIO video driver is loaded early
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelParams = [ "console=tty0" ];

  services.xserver.videoDrivers = [ "virtio" ];
}
