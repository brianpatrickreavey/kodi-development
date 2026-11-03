# Repos

Start Grok in `~/Code/kodi-development`. Each directory below is its own git repo. This repo does not record their commits.

| Directory | GitHub | Role |
|---|---|---|
| `auth0-ciam-client` | https://github.com/brianpatrickreavey/auth0-ciam-client | Python library. A `v*` tag is only a git tag. It does not build a Kodi zip. |
| `kodi.script.module.auth0-ciam-client` | https://github.com/brianpatrickreavey/kodi.script.module.auth0-ciam-client | Login addon. `pyproject.toml` pins a library tag. A `v*` tag builds the zip and puts `auth0_ciam_client` inside it. |
| `kodi.plugin.video.angelstudios` | https://github.com/brianpatrickreavey/kodi.plugin.video.angelstudios | Video addon. Its zip does not contain the library. `addon.xml` requires the login addon. |
| `kodi-addon-builder` | https://github.com/brianpatrickreavey/kodi-addon-builder | Shared build tool used by the addon dev dependencies. |
| `repository.kodi.reavey05.com` | https://github.com/brianpatrickreavey/repository.kodi.reavey05.com | Catalog. Publishes https://repository.kodi.reavey05.com/ |

Not in this directory: `angel-scraper` (research notes), `kodi.plugin.video.crossfitwod`, `kodi.plugin.video.wodi`, `kodi-repository.chad.parry.org`, and `test-semantic-release-for-kodi`.
