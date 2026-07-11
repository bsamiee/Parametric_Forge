# Title         : disko.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/nixos/disko.nix
# ----------------------------------------------------------------------------
# Declarative disk layout consumed by nixos-anywhere at bootstrap and by the installed system for fileSystems rows. GPT with a BIOS-boot partition
# (the Hostinger KVM boots BIOS); swap stays zram-owned.
{host, ...}: {
  disko.devices.disk.main = {
    device = host.disk.device;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
