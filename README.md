# Kodi development

This directory is the process repo for the live Kodi addons. Start Grok here:

```sh
cd ~/Code/kodi-development
grok
```

Grok stores session memory for this repo under `~/.grok/memory-v2/workspaces/`. That folder is not part of this repo. The ship steps below are the copy that a new session can read. Current addon state and this machine's Kodi launch are in [docs/handoff.md](docs/handoff.md).

`./checkout.sh` clones any repo from [repos.md](repos.md) that is not already here. The checkouts are gitignored. Each one keeps its own commits, branches, and GitHub remote.

## Make and CI

The Makefile owns the test and checker commands. GitHub Actions checks out the repo, installs uv and Python, and calls `make`. A `v*` tag builds the zip. This workspace starts the catalog run.

`pytest` mocks `xbmc`. It does not start Kodi. `kodi-addon-checker` checks `addon.xml` and dependency rules for the branch you pass. It does not start Kodi either.

```sh
make test
make validate BRANCH=matrix
make validate BRANCH=nexus
make validate BRANCH=omega
```

On the login addon, a bare `make validate` checks Matrix.

## This machine

`~/.kodi/addons` has symlinks to the checkouts in this directory. That Kodi is the fast check during iteration. The other Kodi installs from **KODI Repository @ reavey05.com** and has no checkout.

Restart Kodi on this machine after the symlinks change.

## Ship

Repeat steps 1–6. Do not tag. Do not raise `addon.xml` on every push.

1. Brian says what to change.
2. Grok edits the repo that owns the change.
3. Grok checks it on this Kodi through the symlink when the change is user-visible.
4. Grok commits and pushes `master` or `main`.
5. GitHub Actions runs that repo's CI.
6. Grok watches the run. A failed run stops here.

A library push does not change the login-addon zip. Login-addon CI still checks out the pinned tag.

Brian decides when to cut a version. Write the version numbers, push, and wait for CI again before any release tag.

- Library change: raise `auth0-ciam-client` `pyproject.toml` and `__init__.py` together. Push tag `vX.Y.Z`. That tag has no release workflow. Then set the login addon `pyproject.toml` pin to that tag and raise its `addon.xml`. Push `master`. Wait for CI.
- Login-addon change with no library change: raise its `addon.xml`. Push `master`. Wait for CI.
- Video-addon code change: raise its `addon.xml`. Push `main`. Wait for CI. Update its test pin when the library tag changed. Skip a video-addon tag when the video addon code did not change.
- CrossFit or Wodi code change: raise its `addon.xml`. Push `main`. Wait for CI. The tag builds the zip. The addon files are at the repo root.

After that CI is green:

7. Grok pushes the `v*` tag. A library tag was already pushed above. The login-addon tag and the video-addon tag start a release.
8. GitHub Actions builds the zip and attaches it to the GitHub Release. No call to the catalog.
9. Grok waits until the zip asset is on the release.

Publishing is a separate kickoff. A tag does not do it.

10. Grok runs `gh workflow run publish-to-gh-pages.yml --repo brianpatrickreavey/repository.kodi.reavey05.com`.
11. GitHub Actions downloads the latest release zip of every addon in `repositories-config.yml`. It publishes https://repository.kodi.reavey05.com/. The dispatch payload is not what selects the zip. If any configured addon has no GitHub Release, or its zip is missing, the job fails and the live catalog stays on the previous publish.
12. Grok watches that run, then checks https://repository.kodi.reavey05.com/addons.xml for the new version.
13. The other Kodi checks for updates. It installs an addon only when the published `addon.xml` version is higher.

GitHub Actions uses the `GITHUB_TOKEN` for that job. There is no personal access token in the addon repos. If this machine is off at step 10, the GitHub Release still exists and the catalog stays on the old zip.

Last catalog publish recorded here: run `41708382489` put `plugin.video.crossfitwod` 0.0.3 and `plugin.video.wodi` 0.0.3 on the live site next to Angel 0.5.8 and the login addon 0.0.5. A fresh Kodi installed Angel 0.5.8 and its dependencies from that catalog on 2026-11-03.
