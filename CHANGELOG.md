# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project tries to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.6] - 2026-09-29

### Changed

- Download the MegaCLI Debian package over https

## [0.2.5] - 2026-09-29

### Changed

- Bracketed shell variables, e.g. ${version} instead of $version

## [0.2.4] - 2026-09-29

### Fixed

- Used the correct mail package name (mailx) on RPM based distros

## [0.2.3] - 2026-09-29

### Fixed

- Exit with a non-zero status when the Slack hook or email list file is missing

## [0.2.2] - 2026-09-29

### Fixed

- Removed ineffective exit inside fstab command substitution

## [0.2.1] - 2026-09-29

### Fixed

- Stopped duplicate output from grep checks in device listing

## [0.2.0] - 2026-09-29

### Fixed

- Replaced expr based no-argument check that printed a stray 1

## [0.1.9] - 2026-09-29

### Fixed

- Self update now downloads to a temporary file, validates it before replacing the script, and treats HTTP errors as failures

## [0.1.8] - 2026-09-29

### Fixed

- Removed stray { in the Debian MegaCLI download URL

## [0.1.7] - 2026-09-29

### Fixed

- Slack alert payload is now valid JSON

## [0.1.6] - 2019-12-15

### Changed

- Fixed false alerting and updated README

## [0.1.5] - 2019-11-26

### Changed

- Updated Ubuntu support

## [0.1.4] - 2019-11-02

### Changed

- Cleaned up update code

## [0.1.3] - 2019-11-01

### Changed

- Cleaned up self update code

## [0.1.2] - 2019-11-01

### Changed

- Cleaned up self update code

## [0.1.1] - 2019-11-01

### Changed

- Changed self update code

## [0.1.0] - 2019-11-01

### Added

- Added self updating code

## [0.0.9] - 2019-10-25

### Added

- Added initial support for RPM based distros

## [0.0.8] - 2019-10-24

### Added

- Added initial support for LSI based ServeRAID and Intel controllers

## [0.0.7] - 2019-10-22

### Changed

- Started breaking out install check into controller specific checks

## [0.0.6] - 2019-10-21

### Changed

- Replaced megaclisas-status with lsscsi

## [0.0.5] - 2019-10-20

### Added

- Added download of megaclisas-status with intention to replace lshw as lshw seems unreliable

### Changed

- Implemented shellcheck recommendation

## [0.0.4] - 2019-10-18

### Changed

- Moved email and Slack alert information to files so addresses are not in script

## [0.0.3] - 2019-10-18

### Added

- Added basic Optimal check

## [0.0.2] - 2019-10-17

### Added

- Added help, version, list and LSI package install code

## [0.0.1] - 2019-10-17

### Added

- Initial base script
