cask "mrv2" do
  version "1.8.5"
  sha256 "24ed3d2e58c500d45e044b5c98ed325e6fe574f490147452cf0bb077890d431a"

  url "https://github.com/ggarra13/mrv2/releases/download/v#{version}/mrv2-v#{version}-Darwin-arm64.dmg"
  name "mrv2"
  desc "Flipbook player and review tool for EXR, ProRes, OCIO and OTIO"
  homepage "https://github.com/ggarra13/mrv2"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on :macos

  app "mrv2.app"
  # The bundle's MacOS launcher resolves its folder without following symlinks; mrv2.sh follows them.
  binary "#{appdir}/mrv2.app/Contents/Resources/bin/mrv2.sh", target: "mrv2"

  zap trash: [
    "~/.filmaura",
    "~/Library/Preferences/com.mrv2.mrv2.plist",
    "~/Library/Saved Application State/com.mrv2.mrv2.savedState",
  ]
end
