#!/bin/bash

# Read current version
CURRENT_VERSION=$(cat VERSION)
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Determine version bump type based on commit message
COMMIT_MSG="$1"

if [[ "$COMMIT_MSG" =~ BREAKING:|breaking:|MAJOR:|major: ]]; then
    # Major version bump (breaking changes)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    echo "Major version bump: Breaking change detected"
elif [[ "$COMMIT_MSG" =~ feat:|FEAT:|feature:|FEATURE:|add:|ADD: ]]; then
    # Minor version bump (new features)
    MINOR=$((MINOR + 1))
    PATCH=0
    echo "Minor version bump: New feature detected"
else
    # Patch version bump (fixes, small changes)
    PATCH=$((PATCH + 1))
    echo "Patch version bump: Bug fix or small change"
fi

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > VERSION

# Update mfile with new version
jq --arg version "$NEW_VERSION" '.version = $version' mfile > mfile.tmp && mv mfile.tmp mfile

echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION"
echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT