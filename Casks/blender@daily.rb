cask "blender@daily" do
  # The builder replaces main's build daily and keeps no stable link to the newest one, so a version written into
  # this file goes stale the next day. The cask reads the newest main build from the builder's index each time
  # Homebrew loads it: `brew upgrade` moves to every new daily with no edit here, and the build's published .sha256
  # checks the download.
  index = ::Utils::Curl.curl("https://builder.blender.org/download/daily/?format=json&v=1", print_stdout: false)
  rows = JSON.parse(index.stdout, symbolize_names: true)
  build = rows.select { |row| row in { branch: "main", platform: "darwin", architecture: "arm64", file_extension: "dmg" } }
              .max_by { |row| row[:file_mtime] }

  version "#{build[:version]}-#{build[:risk_id]},#{build[:hash]}"
  sha256 ::Utils::Curl.curl("#{build[:url]}.sha256", print_stdout: false).stdout.strip

  url build[:url]
  name "Blender Daily"
  desc "3D creation suite at the newest daily build of the main branch"
  homepage "https://builder.blender.org/download/daily/"

  conflicts_with cask: ["blender", "blender@lts"]
  depends_on arch: :arm64
  depends_on macos: :ventura

  app "Blender.app"
  command_wrapper "blender",
                  executable: "#{appdir}/Blender.app/Contents/MacOS/Blender"

  preflight_steps do
    set_permissions "*.app/**/__pycache__", "u+w", recursive: false
  end

  # Blender's Python writes .pyc files into the bundle on every run, so a quarantined bundle whose executable ran
  # by path before its first LaunchServices launch fails Gatekeeper's assessment (a sealed resource is missing or
  # invalid) with a Move to Trash dialog; the notarized build passes `spctl -a -t exec` only while pristine.
  # No quarantine, no assessment.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/Blender.app"]
  end

  zap trash: [
    "~/Library/Application Support/Blender",
    "~/Library/Saved Application State/org.blenderfoundation.blender.savedState",
  ]
end
