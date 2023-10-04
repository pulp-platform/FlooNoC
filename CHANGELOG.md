# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Renamed `*_flit_pkg` to `*_pkg`
- New naming scheme of ports: All AXI ports are now prefixed with `axi_`, all FlooNoC links are now prefixed with `floo_`
- Renamed `floo_param_pkg` to `floo_test_pkg`
- Renamed AXI `resp_t` structs to `rsp_t`
- Changed configuration format to align with upcoming FlooNoC generation script

### Added

- Table based routing support in `narrow_wide_chimney`
- Support for different number of inputs and outputs in `narrow_wide_router`

### Fixed

- Test modules `floo_axi_rand_slave` & `floo_dma_test_node` now support `addr_width > 32`

## [0.1.0] - 2023-06-19

### Added

- Initial early public release
