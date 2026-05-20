#!/bin/bash
# Usage: ./generate_packages.sh <category> <name> <download_url_template> [build_system]

CATEGORY="${1:-prog}"
NAME="${2}"
URL_TEMPLATE="${3}"
BUILD_SYSTEM="${4:-autotools}"

if [ -z "$NAME" ] || [ -z "$URL_TEMPLATE" ]; then
    echo "Usage: $0 <name> <url_template> [build_system]"
    exit 1
fi

# determine latest version
case "$URL_TEMPLATE" in
    *gnu.org*)
        BASE_URL="${URL_TEMPLATE%/*}"
        LATEST=$(curl -s "$BASE_URL/" | grep -oP "${NAME}-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.tar)" | sort -V | tail -1)
        ;;
    *github.com*)
        REPO=$(echo "$URL_TEMPLATE" | grep -oP 'github\.com/\K[^/]+/[^/]+')
        # Use GitHub API to get tarball URL and extract version from it
        JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
        TARBALL_URL=$(echo "$JSON" | grep '"tarball_url"' | cut -d '"' -f 4)
        # Extract version from tarball URL (e.g., https://api.github.com/repos/.../tarball/v1.4.7)
        LATEST=$(echo "$TARBALL_URL" | grep -oP '/tarball/\K.*')
        ;;
    *)
        echo "Cannot autodetect version for URL: $URL_TEMPLATE"
        exit 1
        ;;
esac

if [ -z "$LATEST" ]; then
    echo "Could not determine latest version for $NAME"
    exit 1
fi

FINAL_URL=$(echo "$URL_TEMPLATE" | sed "s/\${VERSION}/$LATEST/g")

mkdir -p "$CATEGORY/$NAME"
cat > "$CATEGORY/$NAME/$NAME.forge" <<EOF
name=$NAME
version=$LATEST
url=$FINAL_URL
depends=
iuse=
build_system=$BUILD_SYSTEM
EOF

echo "Generated $CATEGORY/$NAME/$NAME.forge (version $LATEST)"
