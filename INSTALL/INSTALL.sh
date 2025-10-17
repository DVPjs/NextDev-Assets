#!/bin/bash
CONFIG_FILE="./build.env.txt"
echo "Installer"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "No build.env.txt found!"
    echo "Proceeding in unrestricted mode (defaults only)."
    REQUIRE_ROOT=true
    ENVIRONMENT=prod
    MAX_RAM=8192
    BUILD_PATH="./build"
    USE_BLANK_ENV=true
    LICENSE_FILE="./LICENSE"
    LICENSE_URL="https://raw.githubusercontent.com/DVPjs/NextDev-Assets/refs/heads/main/INSTALL/LICENCE"
    GIT_REPO="https://github.com/DVPjs/NextDev.git"
    GIT_BRANCH="main"
else
    echo "Loading config || $CONFIG_FILE"
    source "$CONFIG_FILE"
fi
if [ "$REQUIRE_ROOT" = "true" ] && [ "$EUID" -ne 0 ]; then
    echo "Root perm required."
    exit 1
fi
if [ ! -f "$LICENSE_FILE" ]; then
    echo "Downloading smth... wait"
    curl -fsSL "$LICENSE_URL" -o "$LICENSE_FILE" || {
        echo "failed to download smth... ByeBye"
        exit 1
    }
fi
echo ""
echo "License downloaded || $LICENSE_FILE"
echo "   Please go to $LICENSE_FILE, scroll to the bottom and set 'ACCEPTED=FALSE' → 'ACCEPTED=TRUE'"
echo ""
while true; do
    ACCEPT_LINE=$(grep -E "^ACCEPTED=" "$LICENSE_FILE" | tail -n 1)
    ACCEPTED_VALUE=$(echo "$ACCEPT_LINE" | cut -d'=' -f2)

    if [ "$ACCEPTED_VALUE" = "TRUE" ]; then
        echo "License accepted. GOOD BOY :p"
        break
    else
        echo "⚠️  License not yet accepted. Edit $LICENSE_FILE and set ACCEPTED=TRUE you dumbass."
        read -p "Press ENTER to check again because you could not do it the first time"
    fi
done
if [ "$USE_BLANK_ENV" = "true" ]; then
    echo "Creating smth. WAIT"
    touch .env
else
    echo "Fetching env from $REMOTE_ENV_URL"
    curl -fsSL "$REMOTE_ENV_URL" -o .env || {
        echo "Failed to fetch the ENV txt file, make sure its a right dir / URL."
        exit 1
    }
fi
if command -v free &> /dev/null; then
    FREE_RAM=$(free -m | awk '/Mem:/ {print $7}')
    if [ "$FREE_RAM" -lt "$MAX_RAM" ]; then
        echo "Only ${FREE_RAM}MB free RAM (target ${MAX_RAM}MB). Build may run out of ram so buy more ram dumbahh"
    fi
else
    echo "'free' command not found — skipping RAM check. next time reinstall it"
fi
export NODE_OPTIONS="--max-old-space-size=${MAX_RAM}"
echo ""
echo "✓ Environment: $ENVIRONMENT"
echo "✓ Max RAM: ${MAX_RAM}MB"
echo "✓ Build path: $BUILD_PATH"
echo "--------------------------------------"

if [ -z "$GIT_REPO" ]; then
    echo "⚠️  No GIT_REPO set in build.env.txt."
    read -p "Enter the Git repo URL to clone: " GIT_REPO
    if [ -z "$GIT_REPO" ]; then
        echo "No repo provided, install aborted."
        exit 1
    fi
fi

if [ -z "$GIT_BRANCH" ]; then
    echo "⚠️  No GIT_BRANCH set, defaulting to 'main'"
    GIT_BRANCH="main"
fi

echo "✓ Ready to install site:"
echo "    $GIT_REPO (branch: $GIT_BRANCH)"
read -p "Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Install canceled."
    exit 1
fi
git clone --branch "$GIT_BRANCH" "$GIT_REPO" "$BUILD_PATH" || {
    echo "Git clone failed. Check repo access or SSH key setup."
    exit 1
}
cd "$BUILD_PATH" || { echo "Could not enter $BUILD_PATH"; exit 1; }
if [ -f package.json ]; then
    echo "✓ Installing dependencies..."
    npm install
else
    echo "No package.json found — skipping npm install. you did smth or i fuck smth up"
fi
if [ "$ENVIRONMENT" = "prod" ]; then
    echo "Building the PROD build"
    npm run build
else
    echo "Launching development environment..."
    npm run dev
fi
echo ""
echo "✓ NextDev setup complete."
echo "CREDITS TO ROADJS"
