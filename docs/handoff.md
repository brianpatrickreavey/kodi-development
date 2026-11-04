# Handoff

Facts from the session that built this directory. A Grok session started in `~/Code` does not load them. Home rules in `~/.grok/rules/` still apply in every session.

## Versions that are on the catalog

https://repository.kodi.reavey05.com/addons.xml lists:

- `plugin.video.angelstudios` 0.5.8
- `plugin.video.crossfitwod` 0.0.3
- `plugin.video.wodi` 0.0.3
- `script.module.auth0-ciam-client` 0.0.5
- `repository.kodi.reavey05.com` 0.1.6

The login zip contains `auth0-ciam-client` tag `v0.2.2`. The video zip does not. A fresh Kodi installed Angel 0.5.8 and its dependencies from this catalog on 2026-11-03 and it worked.

`pyproject.toml` in the login addon pins `auth0-ciam-client.git@v0.2.2`. The library version is `pyproject.toml` and `auth0_ciam_client/__init__.py`, both 0.2.2. Commit `9019186` deleted `setup.py` and `pyproject.sample.toml`. `make build` uses `uv build`.

The changelog inside each addon directory matches the repo-root changelog through the current release. Kodi shows the copy inside the addon directory. The video root changelog also keeps the 0.4.x and older entries. The copy inside `plugin.video.angelstudios/` starts at 0.5.0.

## Not shipped

The video addon reads Continue Watching and resume position. It has no GraphQL mutation, so it does not write watch progress. Logout clears the local session. It does not revoke the Angel token. Watchlist and Top Picks show an error that they are not available yet. `all_content_menu` does nothing.

`angel_authentication.py` uses the library cookie list when it restores a saved session and when it prints session details. The order is `angel_jwt_v3`, then `angel_jwt_v2`, then `angel_jwt`. Commit `f6ae252`. CI run `41731854170` passed. Login uses that same list.

A credentialed GraphQL smoke is not built.

## Login behavior

The login HTTP steps are unchanged. The callback cookie names changed. The library looks up `angel_jwt_v3`, then `angel_jwt_v2`, then `angel_jwt`. The first name that is present wins.

`pytest` can fake those cookie names. It cannot see Angel rename the cookie again. `scripts/live_login_check.py` reads `credentials.txt` and prints cookie names only. `credentials.txt` is gitignored. Do not commit it, print it, or put the password in GitHub CI.

The video addon setting **Log authentication steps** is off by default. While it is on, `kodi.log` can include the Angel email, the login callback URL, and, when Kodi debug logging or debug promotion is on, the start of the login token. The addon warns once before those lines are written.

## CI

Login-addon CI on `master` runs `make test` and `make validate BRANCH=` for Matrix, Nexus, and Omega. `make validate` runs stock `kodi-addon-checker` 0.0.36. Commit `f00c4cf`. Those jobs do not start Kodi.

Each addon release builds its zip and then unpacks it. The job fails unless the zip is one directory named with the addon id, and `addon.xml` in that directory has the same id and the tag version. The login zip must also contain `resources/lib/auth0_ciam_client/__init__.py`. CI runs that check on push, so a tag is not required to see it fail. Login commit `f0e3405`, video commit `d466746`, CrossFit commit `0c7f021`, Wodi commit `179ed6a`. On CrossFit and Wodi, `tools/check_addon_zip.py` and `tools/build_release_zip.sh` are not executable. `kodi-addon-checker` treats an executable file inside those addon trees as an error.

The catalog workflow downloads the latest GitHub Release of every addon in `repositories-config.yml`. CrossFit and Wodi tags `v0.0.3` have those zips. A missing release or a missing zip fails the job, and the live catalog stays on the previous publish. `CENTRAL_PAT` is deleted. A tag does not publish the catalog.

`AGENTS.md` and the Copilot instructions in the library, login addon, and video addon point at `~/Code/kodi-development/README.md` for ship steps. Commits `6764633`, `308b9eb`, and `04ef373`. CI runs `41731826264`, `41731820402`, and `41731854170` passed.

## This machine

Kodi 21.3 and inputstream.adaptive 21.5.25 are installed with pacman. Start Kodi with:

```sh
uwsm-app -- kodi --windowing=wayland --audio-backend=pipewire
```

`~/.config/hypr/hyprland.lua` pins a window matching `(?i)kodi` to workspace 5. That match also hits a window title that contains "kodi", such as a terminal. Stop `kodi.bin` before a relaunch so addon code reloads. The log is `~/.kodi/temp/kodi.log`.

`uv` 0.13.6 is at `~/.local/bin/uv`. The three Angel project repos have Python 3.12 virtualenvs.

Symlinks in `~/.kodi/addons` point at the Angel, login, CrossFit, and Wodi checkouts in this directory. CrossFit and Wodi are linked at the repo root, because `addon.xml` is there. Checked 2026-11-03 while Kodi was stopped. All of them resolve.

Restart Kodi if it was open when those directories moved.

## Left uncommitted in the checkouts

Run `git status` in each checkout. This session left local edits there on purpose:

- Action version pins in workflow files, not pushed.
- `auth0-ciam-client` is one commit ahead of `origin/master`. That commit adds `scripts/live_login_check.py`. Do not push it until Brian asks.
- `kodi.plugin.video.angelstudios/tests/unit/test_final_coverage.py` finds the addon directory from the test file instead of a hard-coded path.
