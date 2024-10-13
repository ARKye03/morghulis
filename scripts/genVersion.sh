#!/usr/bin/env bash

# Check if a tag argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide a version tag as an argument (e.g., v0.1.1)"
    exit 1
fi

tag=$1

# Generate version file
echo $tag > version

# Generate CHANGELOG.md
git cliff --tag $tag -o CHANGELOG.md

# Stage the changes
git add version CHANGELOG.md

# Commit the changes
git commit -m "Bump version to $tag"

# Create an annotated tag
git tag -a $tag -m "Release $tag"

echo "Version bumped to $tag, CHANGELOG.md updated, and tag created."
echo "Please review the changes and push with:"
echo "git push origin main $tag"
