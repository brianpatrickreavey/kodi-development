#!/usr/bin/env bash
# Publish plugin.video.angelstudios from a clean main checkout through the Kodi catalog.
#
# Usage, from the kodi-development directory:
#   scripts/publish-video-addon.sh 0.6.1 "One sentence of release news."
#
# The video-addon checkout must be on main, match origin/main, and have no local edits.
# The version bump commit is the one direct push to main. Every other change stays on
# a feature branch until Brian explicitly says to push it to main.
# The script raises the version, pushes main, waits for CI, tags vX.Y.Z, waits for the
# GitHub Release zip, then runs the catalog workflow. That catalog run publishes the
# latest GitHub Release of every addon in repositories-config.yml.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: scripts/publish-video-addon.sh VERSION \"Release news.\"" >&2
  exit 2
fi

VERSION="$1"
NEWS="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDON_REPO="$ROOT/kodi.plugin.video.angelstudios"
ADDON_GIT_REPO="brianpatrickreavey/kodi.plugin.video.angelstudios"
CATALOG_REPO="brianpatrickreavey/repository.kodi.reavey05.com"
TAG="v${VERSION}"
DATE="$(date +%Y-%m-%d)"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like 0.6.1." >&2
  exit 2
fi
if [[ -z "$NEWS" || "$NEWS" == *$'\n'* || "$NEWS" == *"<"* || "$NEWS" == *">"* || "$NEWS" == *"&"* ]]; then
  echo "News must be one line and must not contain <, >, or &." >&2
  exit 2
fi
if [[ ! -d "$ADDON_REPO/.git" ]]; then
  echo "Missing checkout: $ADDON_REPO" >&2
  exit 1
fi

cd "$ADDON_REPO"
git fetch origin

branch="$(git branch --show-current)"
if [[ "$branch" != "main" ]]; then
  echo "The video addon checkout is on ${branch}. Check out main first." >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "The video addon checkout has local edits. Commit or stash them before publishing." >&2
  git status --short >&2
  exit 1
fi
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]]; then
  echo "Local main does not match origin/main. Pull or push before publishing." >&2
  exit 1
fi
if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  echo "Tag ${TAG} already exists locally." >&2
  exit 1
fi
if git ls-remote --exit-code --tags origin "refs/tags/${TAG}" >/dev/null; then
  echo "Tag ${TAG} already exists on origin." >&2
  exit 1
fi

python3 - "$VERSION" "$NEWS" "$DATE" <<'PY'
import pathlib
import re
import sys

version, news, day = sys.argv[1:]
root = pathlib.Path(".")

def parts(value):
    return tuple(int(piece) for piece in value.split("."))

addon_xml = root / "plugin.video.angelstudios" / "addon.xml"
xml = addon_xml.read_text()
current = re.search(r'<addon id="plugin.video.angelstudios" version="([^"]+)"', xml)
if not current:
    sys.exit("Could not read the addon version.")
old = current.group(1)
if parts(version) <= parts(old):
    sys.exit(f"{version} is not newer than {old}.")
xml = xml.replace(
    f'<addon id="plugin.video.angelstudios" version="{old}"',
    f'<addon id="plugin.video.angelstudios" version="{version}"',
    1,
)
xml, news_count = re.subn(r"<news>.*</news>", f"<news>{version} - {news}</news>", xml, count=1)
if news_count != 1:
    sys.exit("Could not update addon.xml news.")
addon_xml.write_text(xml)

def insert_changelog(path):
    text = path.read_text()
    marker = "---\n"
    start = text.find(marker)
    if start < 0:
        sys.exit(f"No changelog marker in {path}.")
    at = start + len(marker)
    block = f"## [{version}] - {day}\n- {news}\n\n"
    if text[at : at + 1] == "\n":
        at += 1
    path.write_text(text[:at] + block + text[at:])

insert_changelog(root / "CHANGELOG.md")
insert_changelog(root / "plugin.video.angelstudios" / "CHANGELOG.md")

pyproject = root / "pyproject.toml"
project = pyproject.read_text()
project, project_count = re.subn(
    rf'(?m)^version = "{re.escape(old)}"$',
    f'version = "{version}"',
    project,
    count=1,
)
if project_count != 1:
    sys.exit("Could not update pyproject.toml.")
pyproject.write_text(project)

lock_path = root / "uv.lock"
lock = lock_path.read_text()
old_block = f'name = "kodi-plugin-video-angelstudios"\nversion = "{old}"'
new_block = f'name = "kodi-plugin-video-angelstudios"\nversion = "{version}"'
if lock.count(old_block) != 1:
    sys.exit("Could not update uv.lock.")
lock_path.write_text(lock.replace(old_block, new_block, 1))
print(f"Raised {old} to {version}.")
PY

git add \
  plugin.video.angelstudios/addon.xml \
  plugin.video.angelstudios/CHANGELOG.md \
  CHANGELOG.md \
  pyproject.toml \
  uv.lock
git commit -m "Release ${VERSION}. ${NEWS}"
git push origin main
release_sha="$(git rev-parse HEAD)"
echo "Pushed main at ${release_sha}."

wait_for_run() {
  local repo="$1"
  local workflow="$2"
  local sha="$3"
  local run_id=""
  local attempt
  for attempt in $(seq 1 30); do
    run_id="$(gh run list --repo "$repo" --workflow "$workflow" --commit "$sha" --limit 1 --json databaseId --jq '.[0].databaseId')"
    if [[ -n "$run_id" && "$run_id" != "null" ]]; then
      break
    fi
    sleep 2
  done
  if [[ -z "$run_id" || "$run_id" == "null" ]]; then
    echo "No ${workflow} run appeared for ${sha}." >&2
    exit 1
  fi
  echo "Watching ${workflow} run ${run_id}."
  gh run watch "$run_id" --repo "$repo" --exit-status
}

wait_for_run "$ADDON_GIT_REPO" "ci.yml" "$release_sha"

git tag "$TAG"
git push origin "$TAG"
echo "Pushed ${TAG}."
wait_for_run "$ADDON_GIT_REPO" "release.yml" "$release_sha"

asset="plugin.video.angelstudios-${TAG}.zip"
if ! gh release view "$TAG" --repo "$ADDON_GIT_REPO" --json assets --jq '.assets[].name' | grep -qx "$asset"; then
  echo "The release does not have ${asset}." >&2
  exit 1
fi
echo "Release zip is ${asset}."

echo "Publishing the catalog. This uses the latest release of every configured addon."
previous_catalog="$(gh run list --repo "$CATALOG_REPO" --workflow publish-to-gh-pages.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh workflow run publish-to-gh-pages.yml --repo "$CATALOG_REPO"
catalog_run=""
for attempt in $(seq 1 30); do
  catalog_run="$(gh run list --repo "$CATALOG_REPO" --workflow publish-to-gh-pages.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
  if [[ -n "$catalog_run" && "$catalog_run" != "null" && "$catalog_run" != "$previous_catalog" ]]; then
    break
  fi
  catalog_run=""
  sleep 2
done
if [[ -z "$catalog_run" || "$catalog_run" == "null" ]]; then
  echo "The catalog workflow did not start." >&2
  exit 1
fi
echo "Watching catalog run ${catalog_run}."
gh run watch "$catalog_run" --repo "$CATALOG_REPO" --exit-status

for attempt in $(seq 1 30); do
  if curl -fsS "https://repository.kodi.reavey05.com/addons.xml" | grep -q "plugin.video.angelstudios\" version=\"${VERSION}\""; then
    echo "Catalog lists plugin.video.angelstudios ${VERSION}."
    echo "https://repository.kodi.reavey05.com/plugin.video.angelstudios/plugin.video.angelstudios-${VERSION}.zip"
    exit 0
  fi
  sleep 10
done

echo "The catalog workflow finished, but addons.xml does not list ${VERSION} yet." >&2
exit 1
