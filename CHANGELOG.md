# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Update rbac to allow the cronjob to handle PVCs.

## [0.2.1] - 2025-08-27

### Changed

- Change `restartPolicy` from `OnFailure` to `Never`.

## [0.2.0] - 2025-07-28

### Changed

- Update test script so that the test cluster PVCs are deleted if the test is successful.

## [0.1.6] - 2025-07-03

### Changed

- Add `failedJobsHistoryLimit` and `successfulJobsHistoryLimit` in the cronjob.

## [0.1.5] - 2025-06-30

### Changed

- Update recovery cluster image tag.

## [0.1.4] - 2025-06-26

### Fixed

- Fixed indentation issues in the configmap.

## [0.1.3] - 2025-06-04

### Changed

- Move `imagePullPolicy` field from cronjob template to values.

## [0.1.2] - 2025-06-04

### Changed

- Fixed issues preventing chart to be deployed as a subchart in other charts.

## [0.1.1] - 2025-06-04

### Changed

- Fix issues in chart to allow pushing to app catalog.

## [0.1.0] - 2025-06-03

- Repo creation and configuration.

[Unreleased]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.6...v0.2.0
[0.1.6]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/giantswarm/pg-cluster-recovery-test/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/giantswarm/pg-cluster-recovery-test/releases/tag/v0.1.0
