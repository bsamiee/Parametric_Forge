cask "mrv2" do
  version "1.8.6"
  sha256 "ab4a6cf618cdf2db2feff2b481b72780c14526edd097b6ef6ce46e99113bf01d"

  url "https://github.com/ggarra13/mrv2/releases/download/v#{version}/mrv2-v#{version}-Darwin-arm64.dmg"
  name "mrv2"
  desc "Flipbook player and review tool for EXR, ProRes, OCIO and OTIO"
  homepage "https://github.com/ggarra13/mrv2"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on formula: "libidn2"
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
