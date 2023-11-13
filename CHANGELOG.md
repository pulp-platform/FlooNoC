# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Added Chimney Parameters `EnMgrPort` and `EnSbrPort` to properly parametrize Manager resp. Subordinate-only instances of a chimney
- Added `XYRouteOpt` parameter to router to enable/disable routing optimizations when using `XYRouting`

### Changed

- Removed `xy_id_i` ports from AXI chimneys in favor of a generic `id_i` port for both `IdTable` and `XYRouting`

### Fixed

- Fixed missing backpressure in the `NoRoB` version of the reorder buffer, which could lead to overflow of counters

## [0.2.1] - 2023-10-13

### Changed

- Bump dependencies

## [0.2.0] - 2023-10-04

### Changed

- Renamed `*_flit_pkg` to `*_pkg`
- New naming scheme of ports: All AXI ports are now prefixed with `axi_`, all FlooNoC links are now prefixed with `floo_`
- Renamed `floo_param_pkg` to `floo_test_pkg`
- Renamed AXI `resp_t` structs to `rsp_t`
- Changed configuration format to align with upcoming FlooNoC generation script

### Added

- Table based routing support in `narrow_wide_chimney`
- Support for different number of inputs and outputs in `narrow_wide_router`
- Add wrapper for different types of Reorder Buffers in chimneys
- Support for simple RoB-less chimneys with ID counters

### Fixed

- Test modules `floo_axi_rand_slave` & `floo_dma_test_node` now support `addr_width > 32`
- Fixed synchronization issues for ATOP B and R responses

## [0.1.0] - 2023-06-19

### Added

- Initial early public release
