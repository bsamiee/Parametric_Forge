cask "blender@daily" do
  # The builder replaces main's build daily and deletes the one before it, so no version written here outlives a day.
  # Its download action redirects to the one build its filters select, and main is the only alpha track.
  version :latest
  sha256 :no_check

  url "https://builder.blender.org/download/daily/?action=download&platform=darwin&architecture=arm64&release_cycle=alpha"
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
