# Handoff

Facts from the session that built this directory. A Grok session started in `~/Code` does not load them. Home rules in `~/.grok/rules/` still apply in every session.

## Versions that are on the catalog

https://repository.kodi.reavey05.com/addons.xml lists:

- `plugin.video.angelstudios` 0.5.8
- `script.module.auth0-ciam-client` 0.0.5
- `repository.kodi.reavey05.com` 0.1.6

The login zip contains `auth0-ciam-client` tag `v0.2.2`. The video zip does not. A fresh Kodi installed Angel 0.5.8 and its dependencies from this catalog on 2026-11-03 and it worked.

`pyproject.toml` in the login addon pins `auth0-ciam-client.git@v0.2.2`. `pyproject.toml`, `auth0_ciam_client/__init__.py`, and `setup.py` all say 0.2.2. `pyproject.sample.toml` matches the video addon: version 0.5.8, library tag `v0.2.2`, builder tag `v0.4.0`.

The changelog inside each addon directory matches the repo-root changelog through the current release. Kodi shows the copy inside the addon directory. The video root changelog also keeps the 0.4.x and older entries. The copy inside `plugin.video.angelstudios/` starts at 0.5.0.

## Not shipped

The video addon reads Continue Watching and resume position. It has no GraphQL mutation, so it does not write watch progress. Logout clears the local session. It does not revoke the Angel token. Watchlist and Top Picks show an error that they are not available yet. `all_content_menu` does nothing.

`angel_authentication.py` still looks up the cookie name `angel_jwt` when it restores a saved session and when it prints session details. Login itself uses the library cookie list.

A credentialed GraphQL smoke is not built.

## Login behavior

The login HTTP steps are unchanged. The callback cookie names changed. The library looks up `angel_jwt_v3`, then `angel_jwt_v2`, then `angel_jwt`. The first name that is present wins.

`pytest` can fake those cookie names. It cannot see Angel rename the cookie again. `scripts/live_login_check.py` reads `credentials.txt` and prints cookie names only. `credentials.txt` is gitignored. Do not commit it, print it, or put the password in GitHub CI.

The video addon setting **Log authentication steps** is off by default. While it is on, `kodi.log` can include the Angel email, the login callback URL, and, when Kodi debug logging or debug promotion is on, the start of the login token. The addon warns once before those lines are written.

## CI

Login-addon CI on `master` runs `make test` and `make validate BRANCH=` for Matrix, Nexus, and Omega. Commit `122310d`. Those jobs do not start Kodi.

The catalog workflow downloads the latest GitHub Release of every addon in `repositories-config.yml`. CrossFit and Wodi have no release. Those downloads log 404 and the job still succeeds. `CENTRAL_PAT` is deleted. A tag does not publish the catalog.

## This machine

Kodi 21.3 and inputstream.adaptive 21.5.25 are installed with pacman. Start Kodi with:

```sh
uwsm-app -- kodi --windowing=wayland --audio-backend=pipewire
```

`~/.config/hypr/hyprland.lua` pins a window matching `(?i)kodi` to workspace 5. That match also hits a window title that contains "kodi", such as a terminal. Stop `kodi.bin` before a relaunch so addon code reloads. The log is `~/.kodi/temp/kodi.log`.

`uv` 0.13.6 is at `~/.local/bin/uv`. The three Angel project repos have Python 3.12 virtualenvs.

Symlinks in `~/.kodi/addons` point at the Angel and login checkouts in this directory. Checked 2026-11-03 while Kodi was stopped. All three resolve. CrossFit and Wodi are checked out here and are not installed under `~/.kodi/addons`, so they have no symlink.

Restart Kodi if it was open when those directories moved.

## Left uncommitted in the checkouts

Run `git status` in each checkout. This session left local edits there on purpose:

- Action version pins in workflow files, not pushed.
- `AGENTS.md` and Copilot instruction wording, not pushed.
- `auth0-ciam-client` is ahead of `origin/master`. Do not push it until Brian asks. A push would also publish `scripts/live_login_check.py`. The other unpushed library commits only align `setup.py` and `pyproject.sample.toml` with 0.2.2.
- `kodi.plugin.video.angelstudios/tests/unit/test_final_coverage.py` finds the addon directory from the test file instead of a hard-coded path.
