# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-08-27

### Changed
- Configuration UI Changed to support multiple modbus device configurations
- Updated modbus-proxy config file generation based on user input
- Completely rewrote README.md in with modern formatting
- Improved configuration validation and error handling
- Enhanced logging with better error messages
- Optimized addon structure for better maintainability
- Updated config.yaml with proper host_network configuration
- Detailed installation instructions (one-click and manual)
- Configuration parameter documentation with examples
- Troubleshooting section with common issues and solutions
- Support guidelines for issue reporting
- Advanced configuration examples for multiple devices

### Removed
- Local copy of `modbus_proxy.py` (using pip-installed version)
- Empty `src/` directory
- Redundant configuration files

### Fixed
- Port binding issues with host_network configuration
- Configuration parameter handling and defaults
- Error messages and user feedback
- Documentation inconsistencies

### Technical
- Streamlined addon to essential files only
- Improved Docker build efficiency
- Better error handling and logging

## [1.0.1] - Previous Release

### Added
- Enhanced number of modbus devices support to three devices
- Multi-device configuration through Home Assistant UI
- Configurable timeouts and connection parameters

## [1.0.0] - Initial Release

### Added
- Initial fork version with three modbus host configurations
- Basic proxy functionality for single modbus connections
- Home Assistant addon integration
