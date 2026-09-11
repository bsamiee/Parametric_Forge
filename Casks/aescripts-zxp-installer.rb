cask "aescripts-zxp-installer" do
  version "1.8.801"
  sha256 "713c1b5a40da85439913d26584a19afc2491d358d771e51a475ff70461b9fdaa"

  url "https://updates.aescripts.com/zxp-installer/mac/archives/#{version}/aescripts%20+%20aeplugins%20zxp%20installer%20(setup).dmg"
  name "ZXP/UXP Installer"
  desc "Adobe CEP and UXP extension installer"
  homepage "https://aescripts.com/learn/post/zxp-installer"

  livecheck do
    url "https://updates.aescripts.com/zxp-installer/mac/updater.rss"
    strategy :sparkle
  end

  auto_updates true
  depends_on macos: :monterey

  app "ZXP Installer.app"

  uninstall quit: "com.aescripts.ZXP-Installer"
end
