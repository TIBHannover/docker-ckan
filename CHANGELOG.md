# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/) and
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Entries before this file was introduced are not reconstructed here; see the
[GitHub releases](https://github.com/TIBHannover/docker-ckan/releases) and
git tags for the earlier history.

## [Unreleased]

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
