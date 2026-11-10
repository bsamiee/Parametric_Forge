cask "voicebox" do
  version "0.5.0"
  sha256 "89f8e1e2a77683102c40d439562dc14463aa9d87cf2df5a8d51530e6459bea09"

  url "https://github.com/jamiepine/voicebox/releases/download/v#{version}/Voicebox_aarch64.app.tar.gz"
  name "Voicebox"
  desc "Local voice studio with cloning, dictation and an HTTP MCP server"
  homepage "https://github.com/jamiepine/voicebox"

  livecheck do
    url :url
    strategy :github_latest
  end

  # The app's Tauri updater reads the same GitHub release feed, so the bundle can lead this record and
  # activation then leaves it alone.
  auto_updates true
  depends_on arch: :arm64
  depends_on :macos

  app "Voicebox.app"

  # With "keep server running" on, quitting the app leaves Contents/MacOS/voicebox-server on 127.0.0.1:17493,
  # and the next launch reuses any voicebox process holding that port without a version check. Stopping it
  # after the quit makes a replacement bundle start its own backend instead of attaching to the old one.
  uninstall_postflight_steps do
    terminate_process "voicebox-server"
  end

  uninstall quit: "sh.voicebox.app"

  zap trash: [
    "~/Library/Application Support/sh.voicebox.app",
    "~/Library/Caches/sh.voicebox.app",
    "~/Library/WebKit/sh.voicebox.app",
  ]
end
