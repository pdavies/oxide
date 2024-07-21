# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2024-07-21

### Added

- Add `result?` and `assert_result!`

## [0.4.2] - 2024-05-30

### Fixed

- Restore direct raising of exceptions with `Result.unwrap!/1`; that is, `Result.unwrap!({:error, reason})`
  will simply reraise `reason` if `reason` is an exception, and otherwise raise `RuntimeError`.

## [0.4.1] - 2024-05-30

### Fixed

- Support raising from `Result.unwrap!/1` whatever the type of the error reason.

## [0.4.0] - 2024-05-15

### Added

- Add `or_else` to return ok values and execute fallback logic on errors.
- Add `collect` to turn a list of results into a result of a list
- Add `~>/2` again under the suggestively named `Result.Dangerous`

### Changed

- More detailed typespecs

## [0.3.0] - 2024-03-12

### Changed

- Rename `~>/2` to `&&&/2` in order to demote the operator's precedence below `|>`.
  This is uglier but gives the typically desired behaviour when
  continuing a pipeline, e.g. `{:error, nil} &&& f() |> g()` will return `{:error, nil}` whereas
  `{:error, nil} ~> f() |> g()` would pipe `{:error, nil}` into `g`.

## [0.2.0] - 2024-03-05

### Added

- Add `tap_ok` and `tap_err`
- Result types `t()`, `t(v)` and `t(v, e)`, and specs for `Oxide.Result`.
- More docs
- Changelog

### Fixed

- Garbled exdoc summary rendering

## [0.1.0] - 2024-03-03

### Added

- Initial incomplete release
