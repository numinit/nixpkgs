#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts prefetch-npm-deps
set -euo pipefail

version_regex='^v9\.11\.[0-9]+$'

# Get latest ESR version (9.11.x series)
version=$(curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s https://api.github.com/repos/mattermost/mattermost/releases | \
    jq --arg regex "$version_regex" -r '[.[] | select(.tag_name | test($regex))] | .[0].tag_name | sub("^v"; "")')

if [[ "$UPDATE_NIX_OLD_VERSION" == "$version" ]]; then
    echo "Already up to date!"
    exit 0
fi

update-source-version mattermost "$version"

# Generate new npmDepsHash
new_hash=$(FORCE_GIT_DEPS=true prefetch-npm-deps "$(dirname "$0")/package-lock.json")

# Update the npmDepsHash in package.nix
sed -i "s|npmDepsHash = \".*\"|npmDepsHash = \"$new_hash\"|" "$(dirname "$0")/package.nix"
