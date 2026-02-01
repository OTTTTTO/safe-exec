# Changelog

All notable changes to SafeExec will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-01

### Added
- **Global on/off switch** for SafeExec
- New commands: `--enable`, `--disable`, `--status`
- Configuration file `safe-exec-rules.json` now includes `enabled` field
- When disabled, commands execute directly without safety checks
- Audit log includes `bypassed` events when disabled

### Changed
- Improved `is_enabled()` function to handle false correctly
- Updated status display to show current protection state
- Enhanced user feedback for enable/disable operations

### Fixed
- **Critical Bug**: Fixed jq `//` operator treating `false` as falsy
- Now explicitly checks `.enabled == true` instead of `.enabled // true`
- This ensures SafeExec can be properly toggled on/off

### Security Note
⚠️ **Warning**: When SafeExec is disabled, ALL commands execute directly without protection!
Only disable in trusted environments.

## [0.1.3] - 2026-02-01

### Fixed
- **Configuration Fix**: Removed incorrect SafeExec plugin configuration
- SafeExec is now properly configured as a **Skill** (not a Plugin)
- Eliminated startup warning logs about missing plugin skill paths
- Clean separation between Plugin (core extension) and Skill (Agent tool)

### Changed
- Removed `~/.openclaw/extensions/safe-exec/` (incorrect Plugin version)
- Kept `~/.openclaw/skills/safe-exec/` (correct Skill version)
- Updated `openclaw.json` to remove plugin entry for safe-exec

### Technical Details
- **Before**: SafeExec was registered in `plugins.entries.safe-exec`
- **After**: SafeExec is loaded from `skills.load.extraDirs`
- **Benefit**: Correct architecture, no warning logs, proper Skill behavior

## [0.1.2] - 2026-01-31

### Added
- Comprehensive USAGE.md guide (3000+ words)
- CONTRIBUTING.md with contribution guidelines
- CHANGELOG.md following Keep a Changelog format
- release.sh automation script
- RELEASE_NOTES.md for v0.1.2
- .github/workflows/test.yml for CI/CD
- PROJECT_REPORT.md with completion status

### Documentation
- Complete installation guide
- Usage examples and scenarios
- Troubleshooting section
- FAQ (Frequently Asked Questions)
- Best practices guide

## [0.1.1] - 2026-01-31

### Added
- Automatic cleanup of expired approval requests
- `cleanup_expired_requests()` function
- `--cleanup` flag for manual cleanup
- Default 5-minute timeout for requests
- Audit log entries for expiration events

### Improved
- Prevents request database from growing indefinitely
- Automatic cleanup on every command execution
- Better security with request expiration

## [0.1.0] - 2026-01-31

### Added
- Core risk assessment engine
- Command interception system
- Approval workflow
- Audit logging
- Integration with OpenClaw
- Initial documentation

### Security
- 10+ danger pattern detection
- Fork bomb detection
- System directory protection
- Pipe injection prevention

## [0.2.0] - Planned

### Planned
- Web UI for approval management
- Multi-channel notifications (Telegram, Discord)
- ML-based risk assessment
- Batch operation support
- Rate limiting

---

## Links

- [GitHub Repository](https://github.com/yourusername/safe-exec)
- [Issue Tracker](https://github.com/yourusername/safe-exec/issues)
- [Documentation](https://github.com/yourusername/safe-exec/blob/main/README.md)
