cask "blender@daily" do
  version "5.3.0-alpha,0ae04d3e782c"
  sha256 "791091dfa56fa9c659094d6bd9988c8c8cf74e025a749ac984757aac32642e82"

  url "https://cdn.builder.blender.org/download/daily/blender-#{version.csv.first}+main.#{version.csv.second}-darwin.arm64-release.dmg"
  name "Blender Daily"
  desc "3D creation suite at the newest daily build of the main branch"
  homepage "https://builder.blender.org/download/daily/"

  livecheck do
    url "https://builder.blender.org/download/daily/?format=json&v=1"
    strategy :json do |json|
      build = json.select { |row| row["branch"] == "main" && row["platform"] == "darwin" }
                  .select { |row| row["architecture"] == "arm64" && row["file_extension"] == "dmg" }
                  .max_by { |row| row["file_mtime"] }
      next if build.nil?

      "#{build["version"]}-#{build["risk_id"]},#{build["hash"]}"
    end
  end

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
