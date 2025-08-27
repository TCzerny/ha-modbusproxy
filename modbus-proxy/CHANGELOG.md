# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2024-08-27

### Added
- Comprehensive English README.md with professional formatting
- Detailed installation instructions (one-click and manual)
- Configuration parameter documentation with examples
- Troubleshooting section with common issues and solutions
- Integration examples for Home Assistant Energy Dashboard and SolarEdge
- Support guidelines for issue reporting
- Professional GitHub badges and shields
- Advanced configuration examples for multiple devices

### Changed
- Completely rewrote README.md in English with modern formatting
- Improved configuration validation and error handling
- Enhanced logging with better German error messages
- Optimized addon structure for better maintainability
- Updated config.yaml with proper host_network configuration

### Removed
- Unused `generate_config.py` file (config generation moved to run.sh)
- Unused `validate_config.py` file (validation handled by HA schema)
- Local copy of `modbus_proxy.py` (using pip-installed version)
- Empty `src/` directory
- Redundant configuration files

### Fixed
- Port binding issues with host_network configuration
- Configuration parameter handling and defaults
- Error messages and user feedback
- Documentation inconsistencies

### Technical
- Folder renamed back to original `modbus-proxy` for compatibility
- Streamlined addon to essential files only
- Improved Docker build efficiency
- Better error handling and logging

## [2.0.0] - Previous Release

### Added
- Dynamic number of modbus devices support
- Multi-device configuration through Home Assistant UI
- Configurable timeouts and connection parameters

## [1.0.0] - Initial Release

### Added
- Initial fork version with three modbus host configurations
- Basic proxy functionality for single modbus connections
- Home Assistant addon integration
