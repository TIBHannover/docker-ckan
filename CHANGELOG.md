# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/) and
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Entries before this file was introduced are not reconstructed here; see the
[GitHub releases](https://github.com/TIBHannover/docker-ckan/releases) and
git tags for the earlier history.

## [Unreleased]

### Added

- Added `ckanext_sfb_layout` 1.0.4 to the installed extensions. This is a
  key extension for the SFB1368-specific site layout.

### Changed

- Bumped `ckanext-crc1153` from 1.0.3 to 1.0.5 to include the latest
  SFB1153 CSS and page layout fixes.
- Bumped `ckanext-Semantic-Media-Wiki` from 3.0.2 to 3.0.4 for the shared
  Semantic MediaWiki integration used by the project deployments.

### Tested

- Successfully tested the updated CKAN image and plugin configuration with
  the SFB1368 deployment. The integration, including the SFB1368 layout,
  worked as expected.

## [3.2.0]

### Added

- New `ckan/docker-entrypoint.d/04_configure_sfb1153.sh` writes the
  mixed-case legacy settings of the SFB1153 extensions into the CKAN
  config, since `ckanext-envvars` would lowercase them. It only acts when
  the corresponding plugin is enabled in `CKAN__PLUGINS`, so other flavours
  are unaffected:
  - With `machine_link`, `sample_link` or `protocol_link` enabled it sets
    `ckanext.smw.baseUrl` and `ckanext.smw.mediaWiki.api.endpont` from
    `CKAN_SMW_BASE_URL` and `CKAN_SMW_API_ENDPOINT`, and aborts the start
    if either is empty. There are no site-specific defaults in the image.
  - If `CKAN_SMW_USERNAME` and `CKAN_SMW_PASSWORD` are set, it writes them
    to the file at `CKAN_SMW_CREDENTIALS_PATH` (mode `0600`) and sets
    `ckanext.mediaWiki_credentials_path`; without credentials, only
    authenticated SMW actions are disabled.
  - With `crc1153_dcat_profile` enabled and `CKAN_APACHE_JENA_ENDPOINT`
    set, it sets `ckanext.apacheJena.endpoint`.
- `.env.example` documents the `CKAN_SMW_*` and `CKAN_APACHE_JENA_ENDPOINT`
  variables and contains an example `CKAN__PLUGINS` line for the SFB1153
  plugins (#15).

### Changed

- Bumped the SFB1153 extensions (#15):
  - `ckanext-crc1153` (1.0.0 → 1.0.3)
    - Fixed a page template error under CKAN 2.11 and an error in the page
      header.
    - Fixed the error page (HTTP 500) when opening a resource, including in
      the SFB layout.
  - `ckanext-Dataset-Reference` (3.0.2 → 3.0.3)
    - The button and dialog for linking a publication work again under
      CKAN 2.11 (opening and closing the dialog).
    - Submitting and validating a reference is no longer rejected for a
      missing CSRF token.
  - `ckanext-Semantic-Media-Wiki` (3.0.0 → 3.0.2)
    - Fixed a configuration-related error under CKAN 2.11.
    - Fixed an error on the machine link and sample link resource pages
      caused by an undefined helper.
  - `ckanext-organization-group` (1.0.2 → 1.0.3)
    - Fixed a configuration-related error under CKAN 2.11.
  - `ckanext-user-manual` (1.0.1 → 1.0.2)
    - Fixed a configuration-related error under CKAN 2.11.
  - `ckanext-data-comparison` (1.0.1 → 1.0.2)
    - Fixed a configuration-related error under CKAN 2.11.
  - `ckanext-dataset-transfer` (1.0.0 → 1.0.1)
    - Fixed the display of dataset entries in the transfer list under
      CKAN 2.11.
- Deployments that already enable `machine_link`, `sample_link` or
  `protocol_link` must now set `CKAN_SMW_BASE_URL` and
  `CKAN_SMW_API_ENDPOINT` in their `.env`, otherwise the `ckan` container
  fails to start (#15).

## [3.1.0]

### Added

- `ckanext-crc1153` 1.0.0 (CKAN extension for the CRC/SFB 1153 project).

### Fixed

- `ckanext-install.sh` now fails the build on a broken extension install
  (bad tag, wrong repo, mismatched package name) instead of silently
  continuing.
- Added a `start_period` to the `ckan` service healthcheck so the extra
  boot time from additional installed extensions (DB migrations, asset
  rebuild) no longer risks the container flipping to `unhealthy` before
  it has finished starting.
- `.env.example`'s default `CKAN__PLUGINS` now enables `harvest` and
  `dcat`, which were installed but not activated, so harvesting and DCAT
  endpoints work out of the box.

## [3.0.0]

### Breaking

- Bumped `ckan/ckan-base` from `2.10.11-py3.10` to `2.11.6-py3.10`. CKAN
  2.11 replaces Beaker sessions with Flask sessions: `beaker.session.key`
  no longer has any effect and is replaced by `SESSION_COOKIE_NAME`.
  Existing sessions stored in Redis cannot be deserialized with the new
  session backend and will be dropped, logging out all currently logged-in
  users on first restart after the upgrade.
- `SECRET_KEY` is now mandatory. `.env.example`'s
  `CKAN___BEAKER__SESSION__SECRET` had no effect under CKAN 2.11 (it mapped
  to the now-unused `beaker.session.secret` setting) and is replaced by
  `CKAN___SECRET_KEY`; `CKAN___WTF_CSRF_SECRET_KEY` is now also set
  explicitly instead of relying on the `SECRET_KEY` fallback. Anyone
  maintaining their own `.env` must add these two variables themselves
  before upgrading, or CKAN will generate a new, unstable `SECRET_KEY` on
  every container restart, invalidating all sessions each time.
- The `ckan` service's `site_packages` volume mount moved from
  `/usr/lib/python3.10/site-packages` to
  `/usr/local/lib/python3.10/site-packages` — `ckan-base` 2.11 switched
  its underlying OS from Alpine to Debian, which installs pip packages
  under a different path. Anyone overriding this mount in their own
  compose file must update the path.
- Bumped `ckan/ckan-solr` from `2.10-solr9` to `2.11-solr9` to match the
  CKAN 2.11 Solr schema. This is now fully automated: the `solr` service
  is built from a new local `solr/Dockerfile` wrapping `ckan/ckan-solr`,
  which detects a schema mismatch on an existing `solr_data` volume and
  recreates the Solr core from the image's configset; the `ckan` service
  then detects the new schema and triggers a full `search-index rebuild`
  via a new `ckan/docker-entrypoint.d/02_reindex_on_schema_change.sh`
  script. Both steps are idempotent (tracked via the schema name reported
  by Solr and a marker file on the `ckan_storage` volume) and require no
  manual action — expect a longer first startup after this upgrade while
  the index rebuilds, not a manual `ckan search-index rebuild` step.
- Bumped the `db` service's base image from `postgres:12.22-alpine` to
  `pgautoupgrade/pgautoupgrade:16.15-alpine`. On an existing `pg_data`
  volume this automatically runs `pg_upgrade` on first start (a one-time
  longer startup while all databases are upgraded and reindexed), rather
  than requiring a manual dump/restore. A fresh volume is initialized
  directly on Postgres 16 as before; a second restart after the upgrade
  is a no-op. The `docker-entrypoint-initdb.d` scripts under
  `postgresql/` are unaffected — `pgautoupgrade` supports the same
  contract as the official `postgres` image.

### Added

- `make ci-upgrade` verifies the in-place upgrade path against real,
  already-populated volumes rather than a fresh stack: build and start
  the images, capture the Postgres/Solr/CKAN upgrade log markers, then
  restart without rebuilding to confirm all three upgrade steps are
  no-ops the second time around.
- `make ci-integration` (now part of `make ci` and `make ci-upgrade`)
  exercises the resource upload -> DataPusher -> DataStore pipeline
  end to end via `ckan/tools/check-datastore-pipeline.py`: uploads a
  real CSV through the live HTTP API, waits for CKAN's automatic
  DataPusher submission to complete, and checks the data lands in the
  DataStore. This is infrastructure shared by every extension that
  ships resources but exercised by none of them individually, so it
  belongs here rather than in any single extension's own tests.

### Fixed

- Bumped `ckanext-feature-image` from `1.0.2` to `1.0.3`. The `1.0.2`
  release tag was cut just before its CKAN 2.11 compatibility fix was
  merged, so it was missing from that release despite being on `main`;
  `1.0.3` includes it.

## [2.0.0]

### Breaking

- `ckan/ckan-base` 2.10.11 introduced a reference to `EXTRA_UWSGI_OPTS` in
  `start_ckan.sh` without a default, which crashes the `ckan` container at
  startup (`unbound variable`) under `set -u` unless that variable is
  defined. `.env.example` now defines `EXTRA_UWSGI_OPTS=` to keep the
  container starting. Anyone maintaining their own `.env` (not regenerated
  from `.env.example`) must add `EXTRA_UWSGI_OPTS=` themselves before
  upgrading to this version.

### Added

- `make ci` now verifies via the CKAN API that every plugin listed in
  `CKAN__PLUGINS` was actually loaded, catching silently misconfigured or
  broken extensions (`ci-plugins` target).
- `make ci` now also verifies that every webassets bundle registered by
  CKAN core and the installed extensions actually resolves, catching
  extensions that preload a vendor asset bundle no longer shipped by the
  pinned `ckan-base` version (`ci-webassets` target). This is exactly the
  class of bug behind the `vendor/jquery.ui.core` breakage below.

### Fixed

- Extensions preloading the `vendor/jquery.ui.core` webassets bundle
  (removed from `ckan-base` 2.10.11, superseded by `vendor/reorder`) were
  logging `Trying to include unknown asset` and silently dropping their
  JS. Fixed by bumping `ckanext-cancel-dataset-creation` (1.0.0 → 1.0.2),
  `ckanext-close-for-guests` (1.1.7 → 1.1.8),
  `ckanext-dataset-metadata-automation` (1.0.0 → 1.0.1),
  `ckanext-Dataset-Reference` (3.0.0 → 3.0.1),
  `ckanext-email-notification` (1.1.0 → 1.1.1),
  `ckanext-feature-image` (1.0.1 → 1.0.2),
  `ckanext-multiuploader` (2.0.15-test → 2.1.0),
  `ckanext-organization-group` (1.0.0 → 1.0.1),
  `ckanext-tif-imageview` (1.1.0 → 1.1.1) and
  `ckanext-user-manual` (1.0.0 → 1.0.1) (#2). A related, still-open issue
  with the `vendor/select2` bundle is tracked separately.
- Extensions preloading the `vendor/select2` webassets bundle (no longer
  exposed as a standalone JS bundle in `ckan-base` 2.10.11 — the JS is
  bundled inside `vendor/vendor` instead) were logging the same
  `Trying to include unknown asset` error. Fixed by bumping
  `ckanext-cancel-dataset-creation` (1.0.2 → 1.0.3),
  `ckanext-Dataset-Reference` (3.0.1 → 3.0.2) and
  `ckanext-organization-group` (1.0.1 → 1.0.2) (#12).
- `ckanext-cancel-dataset-creation`'s `IResourceController` implementation
  only defined `before_create`, causing `package_show` to crash with
  `AttributeError: ... has no attribute 'before_resource_show'` on any
  dataset with at least one resource. Fixed by bumping
  `ckanext-cancel-dataset-creation` (1.0.3 → 1.0.4), which implements the
  full CKAN 2.10/2.11 resource callback interface.

### Changed

- `.env.example`: added `organization_group` and `scheming_organizations` to
  the active `CKAN__PLUGINS` list — both extensions are baked into the image
  but were not enabled.
- Dependabot now only proposes patch-level updates for `ckan/ckan-base`,
  keeping this branch on its current CKAN minor version until a maintainer
  deliberately upgrades it.
- Dependabot no longer proposes major-version updates for `postgres` —
  a Postgres major upgrade requires a manual `pg_upgrade`/dump-restore
  migration of the data volume, never just a tag bump.
