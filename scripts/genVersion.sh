# Get active tag
tag=$(git describe --tags --abbrev=0)

echo $tag > version
git cliff --current -o CHANGELOG.md
