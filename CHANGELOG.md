# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2021-05-25

### Changed

- The command execution context now has to be set explicitly.
  - Prior to this release it was set from the GitHub Actions workflow name, however that doesn't allow for flexibility
    when using job strategies.

## [0.1.2] - 2021-04-23

### Changed

- Added support for `docker-image-builder` via the `docker-image-build` command.
  - The new command expects an additional optional `build_args` input that provides a string of build arguments
    that will be passed into the Docker container that is being built. 
    - Multiple arguments must be supplied to the action as multiple instances of the `--build-arg` flag like this - 
      `build_args: --build-arg ARG1 --build-arg ARG2`.

## [0.1.1] - 2021-03-04 

### Changed

- Updated `README.md` to provide more information as comments on the GitHub action example.

## [0.1.0] - 2021-02-22

### Added

- Composite run GitHub Action for invoking the ECS deploy runner.
- Helper scripts that install the dependencies of the action.

[0.2.0]: https://github.com/distil/ecs-deploy-runner-github-action/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/distil/ecs-deploy-runner-github-action/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/distil/ecs-deploy-runner-github-action/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/distil/ecs-deploy-runner-github-action/releases/tag/v0.1.0