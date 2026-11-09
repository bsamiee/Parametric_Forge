# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/unreal/default.nix
# ----------------------------------------------------------------------------
# Unreal Engine per-user UnrealBuildTool configuration: UBT reads this XmlConfig file for every build on the machine, the editor's own included.
_: {
  # UBA's executor crashes in libUbaHost.dylib on this Mac (UE 5.8.3 and 5.8.4, exit 133), and builds pass with it off; the row goes once a
  # UE release fixes the crash.
  home.file."Library/Application Support/Unreal Engine/UnrealBuildTool/BuildConfiguration.xml".text = ''
    <?xml version="1.0" encoding="utf-8" ?>
    <Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
      <BuildConfiguration>
        <bAllowUBAExecutor>false</bAllowUBAExecutor>
      </BuildConfiguration>
    </Configuration>
  '';
}
