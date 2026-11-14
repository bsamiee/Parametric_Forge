cask "voicebox" do
  version "0.5.0"
  sha256 "89f8e1e2a77683102c40d439562dc14463aa9d87cf2df5a8d51530e6459bea09"

  url "https://github.com/jamiepine/voicebox/releases/download/v#{version}/Voicebox_aarch64.app.tar.gz"
  name "Voicebox"
  desc "Local voice studio with cloning, dictation and an HTTP MCP server"
  homepage "https://github.com/jamiepine/voicebox"

  livecheck do
    url "https://github.com/jamiepine/voicebox/releases/latest/download/latest.json"
    strategy :json do |json|
      json["version"] if json.dig("platforms", "darwin-aarch64")
    end
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on :macos

  app "Voicebox.app"

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
