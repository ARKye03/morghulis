#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Check if a tag argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide a version tag as an argument (e.g., v0.1.1)"
    exit 1
fi

tag=$1

# Check if the tag already exists
if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "Error: Tag $tag already exists. Please choose a different tag."
    exit 1
fi

# Generate version file
echo $tag > version

git cliff --tag $tag -o CHANGELOG.md
git add version CHANGELOG.md
git commit -m "chore: bump version to $tag"
git tag -s $tag -m "Release $tag"

echo "Version bumped to $tag, CHANGELOG.md updated, and signed tag created."
echo "Please review the changes and push with:"
echo "git push origin main $tag"
