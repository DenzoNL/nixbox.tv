#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github git

set -euo pipefail

cd "$(dirname "$0")"

# Fetch latest release from GitHub API
echo "Fetching latest cs2mqtt release..."
latest_version=$(curl -s https://api.github.com/repos/lupusbytes/cs2mqtt/releases/latest | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = ' default.nix | sed 's/.*version = "\(.*\)".*/\1/')

if [ "$latest_version" = "$current_version" ]; then
    echo "Already up to date at version $current_version"
    exit 0
fi

echo "Updating from $current_version to $latest_version"

# Get the new source hash
echo "Fetching source hash..."
new_hash=$(nix-prefetch-github lupusbytes cs2mqtt --rev "v$latest_version" | jq -r .hash)

# Update version and hash in default.nix
sed -i "s/version = \".*\"/version = \"$latest_version\"/" default.nix
sed -i "s|sha256 = \".*\"|sha256 = \"$new_hash\"|" default.nix

# Ensure the package is tracked in git for flake to see it
git add default.nix

# Generate new deps.json using NixOS's built-in fetch-deps
echo "Generating new deps.json..."
echo "This will download and restore all NuGet dependencies..."

# Build the fetch-deps derivation and run it
nix build ../../#nixosConfigurations.nixbox.pkgs.cs2mqtt.fetch-deps
./result deps.json
rm -f result

echo "Testing build..."
nix build ../../#nixosConfigurations.nixbox.pkgs.cs2mqtt --no-link

echo "✅ Successfully updated cs2mqtt to version $latest_version"
echo ""
echo "Changes made:"
echo "  - Updated version in default.nix"
echo "  - Updated source hash"  
echo "  - Regenerated deps.json"
echo ""
echo "Please review the changes and commit if everything looks good:"
echo "  git add -A packages/cs2mqtt/"
echo "  git commit -m \"cs2mqtt: $current_version -> $latest_version\""