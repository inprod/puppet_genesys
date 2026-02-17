# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-02-17

### Breaking Changes
- Minimum Puppet version raised from 4.x to 7.x
- Provider file renamed from `ruby.rb` to `inprod.rb` (aligns with provider name)
- Provider methods renamed to snake_case (`ChangeSetAPI` -> `changeset_api`, `ChangeSetExecuteJson` -> `changeset_execute_json`)
- **Authentication**: Replaced username/password token auth with API key authentication (`Api-Key` header). Removed `apiusername` and `apipassword` parameters. Added `apikey` parameter.
- **Async operations**: All execute and validate operations now run as background tasks. The provider polls for task completion using the `/api/v1/task-status/` endpoint.
- **API URL paths**: Updated to match current InProd API structure.

### Added
- SSL/TLS support for HTTPS connections (auto-detected from URI scheme)
- HTTP response code checking — non-2xx responses now raise `Puppet::Error`
- `apikey` parameter (sensitive) — API key for authentication
- `environment` parameter — optional target environment override (ID or name) for JSON-based actions
- `timeout` parameter — max seconds to wait for task completion (default: 300)
- `poll_interval` parameter — seconds between status polls (default: 5)
- Task status polling with support for PENDING, STARTED, SUCCESS, FAILURE, and REVOKED states
- Detailed validation error formatting with action IDs and field-level messages
- Modern test framework (`puppetlabs_spec_helper`, `rspec-puppet`)
- `Gemfile` and `Rakefile` for dependency management and test/lint tasks
- `.fixtures.yml` for spec helper module symlink
- `.rubocop.yml` for Ruby style enforcement
- Unit tests for type, provider, and class
- `CHANGELOG.md`
- `metadata.json` fields: `requirements`, `operatingsystem_support`, `tags`

### Fixed
- Bare `elsif` without condition (3 instances) — changed to `else`
- File handle leak in `changeset_execute_json` — now uses `File.read`
- `apihost` validation error message using literal `%s` instead of interpolation
- `changesetid` regex now anchored (`/\A[0-9]+\z/`) to prevent partial matches
- `puts` debug output replaced with `Puppet.debug`
- Missing comma in `executejson.pp` example

### Removed
- `apiusername` parameter
- `apipassword` parameter
- `connect` method (username/password token exchange)
- `valid_json?` helper (no longer needed with structured JSON responses)
- Unused `InProd::Error` custom exception class
- Legacy `tests/` directory (superseded by `examples/`)
- Hand-maintained `types` block from `metadata.json` (auto-generated at build time)
- Dead Puppet 5.5 documentation URL from type comments

## [1.0.0] - 2018-01-01

### Added
- Initial release
- Support for validate, execute, and executejson changeset actions
- Token-based authentication with InProd API
