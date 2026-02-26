#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 <version> <artifact-path>}"
ARTIFACT="${2:?Usage: $0 <version> <artifact-path>}"
TAP_REPO="maferland/homebrew-tap"

SHA256=$(shasum -a 256 "$ARTIFACT" | awk '{print $1}')
URL="https://github.com/maferland/switchboard/releases/download/${VERSION}/$(basename "$ARTIFACT")"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone "https://x-access-token:${GH_TOKEN}@github.com/${TAP_REPO}.git" "$TMPDIR/tap"

cat > "$TMPDIR/tap/Casks/switchboard.rb" <<CASK
cask "switchboard" do
  version "${VERSION#v}"
  sha256 "${SHA256}"

  url "${URL}"
  name "Switchboard"
  desc "Auto-switch audio and video devices when you dock your Mac"
  homepage "https://github.com/maferland/switchboard"

  depends_on macos: ">= :sonoma"

  binary "Switchboard", target: "switchboard"

  postflight do
    system_command "launchctl",
                   args: ["load", "#{ENV["HOME"]}/Library/LaunchAgents/com.maferland.switchboard.plist"],
                   sudo: false
  end
end
CASK

cd "$TMPDIR/tap"
git add -A
git commit -m "switchboard ${VERSION}"
git push
