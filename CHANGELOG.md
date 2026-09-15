# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/) and
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Entries before this file was introduced are not reconstructed here; see the
[GitHub releases](https://github.com/TIBHannover/docker-ckan/releases) and
git tags for the earlier history.

## [Unreleased]

### Added

- `make ci` now verifies via the CKAN API that every plugin listed in
  `CKAN__PLUGINS` was actually loaded, catching silently misconfigured or
  broken extensions (`ci-plugins` target).

### Changed

- `.env.example`: added `organization_group` and `scheming_organizations` to
  the active `CKAN__PLUGINS` list — both extensions are baked into the image
  but were not enabled.
