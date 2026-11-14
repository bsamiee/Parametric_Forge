{applications, ...}: let
  settings = {
    schemes = [
      {
        "if".device.category = "mouse";
        pointer = {
          acceleration = 0;
          speed = 0.25;
        };
        buttons.universalBackForward = true;
      }
      {
        "if".device = {
          vendorID = "0x046d";
          productID = "0xb034";
        };
        logitech.highResolutionWheel = true;
        pointer = {
          hardwareDPI = 3200;
          speed = 0.0544;
        };
        scrolling.smoothed = {
          vertical = {
            preset = "easeIn";
            response = 0;
            speed = 0.9;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
          horizontal = {
            preset = "smooth";
            response = 0.15;
            speed = 6.5;
            acceleration = 0;
            inertia = 0;
            bouncing = false;
          };
        };
      }
      {
        "if" = {
          app = applications.rhino.id;
          device = {
            vendorID = "0x046d";
            productID = "0xb034";
          };
        };
        scrolling = {
          distance.vertical = 3;
          smoothed = {
            vertical.enabled = false;
            horizontal.enabled = false;
          };
        };
      }
      {
        "if" = {
          app = applications.blender.id;
          device = {
            vendorID = "0x046d";
            productID = "0xb034";
          };
        };
        scrolling = {
          distance.vertical = 1;
          smoothed = {
            vertical.enabled = false;
            horizontal.enabled = false;
          };
        };
      }
    ];
  };
in {
  xdg.configFile."linearmouse/linearmouse.json".text = builtins.toJSON settings;
}
