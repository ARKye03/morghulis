# Generate new version
tag=$1

echo $tag > version
git tag -s $tag -m "bump version $tag"
git cliff --current -o CHANGELOG.md
