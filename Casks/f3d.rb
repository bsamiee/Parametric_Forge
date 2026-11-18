cask "f3d" do
  version "4.0.1"
  sha256 "4350a31b5e196d99758d95e9dc785be3bf6ba91509aadba80c50c93b16413097"

  url "https://github.com/f3d-app/f3d/releases/download/v#{version}/F3D-#{version}-macOS-arm64.dmg"
  name "F3D"
  desc "Viewer and offscreen renderer for glTF, USD, FBX, Alembic, STL, and Draco"
  homepage "https://f3d.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on :macos

  app "F3D.app"
  binary "#{appdir}/F3D.app/Contents/MacOS/f3d"

  zap trash: [
    "~/.config/f3d",
    "~/Library/Saved Application State/app.f3d.F3D.savedState",
  ]
end
