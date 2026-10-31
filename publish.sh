#!/bin/sh
# Pull the latest release of each app, rebuild the signed index, replace the Pages site.
# One orphan commit each time so old APKs do not pile up in git history.
set -e
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
set -a; . "$HOME/.secrets/fdroid-repo.env"; set +a
token="$(cat "$HOME/.secrets/github.token")"

fetch() { # repo package source-dir
  url=$(curl -fsS -H "Authorization: Bearer $token" "https://api.github.com/repos/altyb/$1/releases/latest" |
    python3 -c "import sys,json;print(next(a['browser_download_url'] for a in json.load(sys.stdin)['assets'] if a['name'].endswith('.apk')))")
  version=$(basename "$url" .apk | sed 's/.*-//')
  rm -f repo/"$2"_*.apk
  curl -fsSL --retry 8 --retry-all-errors -C - -o "repo/$2_$version.apk" "$url"
  rm -rf "metadata/$2"
  cp -r "$3/fastlane/metadata/android" "metadata/$2"
}
fetch shoebill dev.altayeb.shoebill /data/projects/anon-player
fetch hudhud dev.altayeb.hudhud /data/projects/anon-keyboard

fdroid update --pretty 2>&1 | grep -E 'WARNING|ERROR|CRITICAL' || true
test -s repo/index-v2.json

rm -rf .git
git init -q -b main
git add .gitignore README.md icon.png index.html publish.sh repo
git -c user.name=Altayeb -c user.email=altybanony@gmail.com commit -qm "Update repo"
git -c http.extraHeader="Authorization: Basic $(printf 'altyb:%s' "$token" | base64 -w0)" \
  push -qf https://github.com/altyb/fdroid.git main
