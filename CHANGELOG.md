# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

#### Hardware
- The `floo_pkg` was extended with helper functions to calculate the size of AXI payloads and mapping of AXI to Floo Channels. (https://github.com/pulp-platform/FlooNoC/pull/65)
- Multiple configuration structs were introduced to enable a more flexible and non-verbose configuration of the FlooNoC modules. (https://github.com/pulp-platform/FlooNoC/pull/65)
  - The `AxiCfg` describes all the necessary parameters needed for the type definitions of a bidirectional AXI interface
  - The `RouteCfg` describes all the necessary routing information parameters required by the chimneys.
  - The `ChimneyCfg` describes all other parameters for the data path of the chimney (e.g. Mgr/Sbr port enable, number of oustanding transactions, RoB types & sizes, etc.)
- The `floo_test_pkg` now defines default configurations for all the new configuration structs that are used by the testbenches. (https://github.com/pulp-platform/FlooNoC/pull/65)
- Add `floo_axi_router` module, which is a wrapper similar to the `floo_nw_router` but for single-AXI configurations, and can be used in conjunction with `floo_axi_chimney`. (https://github.com/pulp-platform/FlooNoC/pull/69)
- `floo_nw_join` now also allows to convert to a narrow AXI interface, which is useful for accessing peripherals for instance.
- The atomic adapter in `floo_nw_join` can now be disabled with `EnAtopAdapter`.

#### FlooGen
- The `data_width` and `user_width` fields for `protocols` are now also validated to be compatible with each other. (https://github.com/pulp-platform/FlooNoC/pull/65)
- All the various `*Cfg`'s is now rendered by _FlooGen_, either in the `*_noc_pkg` or in the `*_noc` module itself. (https://github.com/pulp-platform/FlooNoC/pull/65)
- Added support for single-AXI configuration networks. (https://github.com/pulp-platform/FlooNoC/pull/69)
- Support for negative increments when specifying a `src_range` or `dst_range` in the `connections` schema. (https://github.com/pulp-platform/FlooNoC/pull/77)
- Add support for multiple non-contiguous address ranges for endpoints. (https://github.com/pulp-platform/FlooNoC/pull/80)
- Added a `sam_idx_e` enum in the package, which allows to directly index into the system address map. (https://github.com/pulp-platform/FlooNoC/pull/111)

### Changed

#### Hardware

- The `floo_narrow_wide_*` modules and the corresponding testbenches were renamed to `floo_nw_*` to be more concise. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The flit type definitions are now implemented as SystemVerilog macros in `typedef.svh`. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The parametrization of the chimney modules has changed dramatically. They now use the newly introduced `*Cfg`'s from the `floo_pkg`. In the narrow-wide chimneys, both datapaths now have their own configs (i.e. `*CfgN` and `*CfgW`), to reduce the verbosity of the module instantiation. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The payload field name in each `*_chan_t` type previously had its own name. This was unified to `payload` since `*_chan_t` already determines the type of the payload. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The input and output buffer FIFO depth of the routers were renamed to `InFifoDepth` and `OutFifoDepth` to be more consistent (previously `ChannelFifoDepth` and `OutputFifoDepth`). (https://github.com/pulp-platform/FlooNoC/pull/65)
- The narrow-wide router wrapper now also requires the `AxiCfg` structs to redefine the link types internally. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The `ReorderBufferSize` parameters was shortened to `RoBSize`. (https://github.com/pulp-platform/FlooNoC/pull/65)
- All testbenches were adapted to all changes. (https://github.com/pulp-platform/FlooNoC/pull/65)
- All verification IPs were adapted to the new configuration structs. (https://github.com/pulp-platform/FlooNoC/pull/65)
  Added spill registers for outgoing AW requests in the chimneys. This is necessary since AXI allows to wait for AW *and* W to be valid before asserting the ready. Since, the AW and W beats are sent over the same channel, this might cause a deadlock if there there are no buffers downstream.

#### FlooGen
- The link typedefs are now renderd with the macros in `typedef.svh` instead of rendering them in pure SystemVerilog. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The template files were renamed to use the more concise `nw` naming scheme. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The generated modules and packages of _FlooGen_ are now named `floo_*_noc` resp. `floo_*_noc_pkg` which is more consistent since all other modules have the `floo_*` prefix. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The `protocols` schema was adapted a bit to be more intuitive. (https://github.com/pulp-platform/FlooNoC/pull/65)
  - The `type` field was renamed to `protocol`, which currently only accepts `AXI4`. A new `type` field now is used by _FlooGen_ to now where to attach the protocol in the network interface. Currently, _FlooGen_ only supports the narrow-wide AXI configuration, hence only `narrow|wide` is allowed as `type` values.
  - The `direction` field in the `protocol` schema is no longer required, since the direction is determined when specifying `mgr_port_protocol` and `sbr_port_protocol`.
  - The `name` field must be unique now, since it is used by `mgr_port_protocol` and `sbr_port_protocol` to reference the exact protocol.
  - All examples were adapted to reflect those changes.
- A _FlooGen_ configuration file now requires a `network_type` field, to determine the type of network to generate. The options are `axi` for single-AXI networks and `narrow-wide` for the narrow-wide AXI configurations.  (https://github.com/pulp-platform/FlooNoC/pull/69)
- The system address map `Sam` is now sorted correctly and can be indexed with `ep_id_e` values. (https://github.com/pulp-platform/FlooNoC/pull/72)
- `id_offset` was renamed to `xy_id_offset`, since this is now only applicable in `XYRouting` networks. An ID offset does not make sense for other types of routing algorithms. The use of `id_offset` is anyway not recommended anymore, since the direction of the connections can be specified in the `connections` schema. (https://github.com/pulp-platform/FlooNoC/pull/72)
- Endpoint names in the `ep_id_e` enum, which are created as 2D arrays now have clearer naming scheme by prefixing them with `X` and `Y`. (https://github.com/pulp-platform/FlooNoC/pull/90)
- The package and the top-module of the generated network are now seperated into its own modules `floo_*_noc.sv` and `floo_*_noc_pkg.sv`. (https://github.com/pulp-platform/FlooNoC/pull/110)
- The `--only-pkg` and `-only-top` flags were added to the _FlooGen_ CLI to omit the generation of the package resp. the top-module. (https://github.com/pulp-platform/FlooNoC/pull/110)
- If `--outdir` resp. `-o` is not specified _FlooGen_ will print the generated files to stdout instead of writing them to a file. (https://github.com/pulp-platform/FlooNoC/pull/110)

### Fixed

- A bug in the calcuation of the RoB offset in `floo_rob` was fixed. Previously, the allocation and the write process used the same counter in bursts for offset calculation, which resulted in wrong offsets. (https://github.com/pulp-platform/FlooNoC/pull/65)
- Routers with `XYRouting` do now use the global `id_offset`, which was previously not accounted for (or had to be specified manually). (https://github.com/pulp-platform/FlooNoC/pull/72)
- Fixed elaboration errors in the chimneys that occured. (https://github.com/pulp-platform/FlooNoC/pull/75)
- Fixed Synopsys DC elaboration error due to concatenation in `id_i` port connection of chimneys and routers. (https://github.com/pulp-platform/FlooNoC/pull/103)

### Removed

#### Hardware

- As the flit type definitions were moved to `typedef.svh`, the auto-generated `floo_*_pkg` packages were removed from the repository. Furthermore, all the (global) imports of those packages in the modules were replaced by parameters. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The testbench `tb_floo_nw_chimney` was removed since it was neither used nor maintained anymore. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The `IdIsPort` routing algorithm was removed since it can only be used for routes over a single router. The same functionality can be achieved with the `SourceRouting` algorithm. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The `dma_mesh` testbench was removed in favor of `nw_mesh` and `axi_mesh` which use generated networks with _FlooGen_. (https://github.com/pulp-platform/FlooNoC/pull/72)

#### FlooGen
- The package generation was removed from _FlooGen_ since it is now handled by the `typedef.svh` file. Further, the `--only-pkg` and `--pkg-outdir` flags were removed from the _FlooGen_ CLI. (https://github.com/pulp-platform/FlooNoC/pull/65)
- The calculation of link sizes and AXI to Floo channel mapping was removed from the _FlooGen_ configuration file. This is now handled by the `floo_pkg` helper functions. (https://github.com/pulp-platform/FlooNoC/pull/65)

## [0.5.0] - 2024-09-13

### Added

- Support for source-based routing algorithm in routers, chimnyes and `floogen`. The route is encoded in the header as a `route_t` field, and each router consumes a couple of bits to determine the output ports. In the chimney, a two-stage encoder was added to first determine the destination ID of the request, and then retrive the pre-computed route to that destination from a table. The `floogen` configuration was extended to support the new routing algorithm, and it will also generate the necessary tables for the chimneys.
- Chimneys now support multiple AXI IDs for non-atomic transactions by specifying the `MaxUniqueids` parameter. This will mitigate ordering of transactions from initially different IDs or endpoints at the expense of some complexity in the `meta_buffer` which then uses `id_queue` to store the meta information required to return responses.
- The conversion from req/rsp with different ID widths from/to NoC has been moved from the chimneys to the `floo_meta_buffer` module.
- Added virtual channel router `floo_vc_router` and corresponding `floo_vc_narrow_wide_chimney`. Currently only supports XY-Routing and mesh topologies.
- Preliminary support for multiple local ports in the routers.
- Additional traffic pattern generation and visualization.
- Added option in `floogen` to define the direction of `connections` to/from routers with `dst_dir` and `src_dir` flags. This replaces the previous `id_offset` flag for that purpose. Specifying the direction of the connection is useful for mesh topologies with `XYRouting`, but also for tile-based implementation, where the order of the ports matters resp. needs to be known.
- `routers` in `floogen`  can no be configured with `degree` to overwrite the number of ports. This is manily useful for tile-based implementations, where all tiles should have identical routers.

### Changed

- `floo_route_comp` now supports source-based routing, and can output both destination ID and a route to the destination.
- The chimneys have an additional port `route_table_i` to receive the pre-computed routing table that is generated by `floogen`.
- System address map was renamed from `AddrMap` to `Sam`.
- The destination field in the flit header have a new type `dst_t` which is either set to `route_t` for the new source-based routing algorithm, and `id_t` for all the other routing algorithms.
- Bumped `idma` dependency to `0.6`
- Renamed `rsvd` field in flits to `payload` to better reflect its purpose.
- Reordered directions in `route_direction_e` to better support multiple local ports.
- Moved all system related rendered parameters from the flit package to its own package in `my_system_floo_noc.sv`. This allows to use the auto-generated routing information for tile-based implementations, that are assembled by hand.
- The `bidirectional` flag for `connections` in `floogen` is set to `true` by default, since uni-directional links are currently not supported.
- The System Address now needs to be passed as a parameter in the `chimneys`, since it is not part of the flit packages anymore.

### Fixed

- The generation of the unique ID has been changed resp. aligned for 2D meshes to increment Y-first and X-second. This way the address range and ID increment are consistent with each other.
- Broadcasted input `id_i` in the chimneys should not throw an error anymore in elaboration.
- The `id_offset` should not be correctly applied in the system address map. Before it resulted in negative coordinates.
- The `axi_ch_e` types now have an explicit bitwidth. Previously, this caused issues during elaboration since a 32-bit integer was used as a type.
- Fixed a typedef in `floo_vc_arbiter` when setting `NumVirtChannels` to 1, that caused issue when compiling with Verilator.
- Fixes issue that the routing table was not renderred when `IdTable` was used as the routing algorithm.

### Removed

- Removed all `floo_synth*` wrapper modules. They are moved to the internal PD repository, since they are not really maintained as part of the FlooNoC repository.

## [0.4.0] - 2024-02-07

### Added

- Added assertions to XY routers with routing optimization enabled to catch packets that want to Y->X which is illegal in XY routing.

### Changed

- The parameters `EnMgrPort` and `EnSbrPort` are swapped in the chimneys to be more consistent. FlooNoC defines subordinate ports as requests that go out of the NoC to AXI subordinates (i.e. memories) that return a response, and manager ports as requests that come into the NoC from AXI managers (i.e. cores).
- The `floo_narrow_wide_join` now uses `axi_riscv_atomics` to filter out atomic operations. The `atop_filter` are still there but are disabled by default.

### Fixed

- Synthesis wrappers now use the more generic `id_t` instead of the deprecated `xy_id_t` type as a parameter.
- The specified ID offset is now also rendered for routers in `floogen`.
- Fixed a template rendering issue where XY routers could not be rendered when the first direction (`EJECT`) was not defined.

### Removed

- Removed `floo_synth_mesh`, `floo_synth_mesh_ruche` & `floo_synth_router_simple` synthesis wrappers, since they are not used anymore.

## [0.3.1] - 2024-01-16

### Added

- `floo_narrow_wide_join` which joins a narrow and a wide AXI bus

### Changed

- Wormhole routing for bursts was removed for some channels in the chimney since it is generally not necessary if the header information is sent in parallel to the payload.

### Fixed

- Output directory passed to `floogen` is now relative to the current working directory instead of the installation folder of `floogen`.
- Write ordering in the narrow-wide version was incorrect. Sending `AW` and `W` beats over different channels would have allowed to arrive them out of order, if multiple managers are sending write requests to the same subordinate, which could result in interleaving of the data. This is now fixed by sending `AW` and `W` beats over the same wide channel. The `AW` and `W` beats are coupled together and wormhole routing prevents interleaving of the data.

## [0.3.0] - 2024-01-09

### Added

- Added NoC generation framework called `floogen`. Also added documentation for `floogen` in the `docs` folder.
- Added Chimney Parameters `EnMgrPort` and `EnSbrPort` to properly parametrize Manager resp. Subordinate-only instances of a chimney
- Added `XYRouteOpt` parameter to router to enable/disable routing optimizations when using `XYRouting`

### Changed

- the exported include folder of the `floo` package is moved to `hw/include`.
- The `LICENSE` file was updated to reflect that the project uses the `Solderpad Hardware License Version 2.1` for all `hw` files and the `Apache License 2.0` for software related files.
- The directory was restructured to accomodate the new `floogen` framework. The `src` was renamed to `hw`, which contains only SystemVerilog code. Test modules and testbenches were also moved to `hw/test` and `hw/tb` respectively. The same holds true for wave files, which are now located in `hw/tb/wave`.
- The SV packages `floo_axi_pkg` and `floo_narrow_wide_pkg` are now generated by `floogen`. The configuration files were moved to the `floogen/examples` folder, and were aligned with the new `floogen` configuration format, that is written in `YAML` instead of `hjson`.
- Reworked the python dependencies to use `pyproject.toml` instead of `requirements.txt`. Furthermore, the python requirement was bumped to `3.10` due to `floogen` (which makes heavy use of the newer `match` syntax)
- Removed `xy_id_i` ports from AXI chimneys in favor of a generic `id_i` port for both `IdTable` and `XYRouting`
- Changed auto-generated package configuration schema. The `header` field is replaced in favor of a `routing` field that better represents the information needed for routing.
- `XYRouting` now also supports a routing table similar to the `IdTable` routing table. Before the destination was determined based on a couple of bits in the address. This however did not allow for a lot of flexibility and requires a larger addres width.

### Fixed

- Fixed missing backpressure in the `NoRoB` version of the reorder buffer, which could lead to overflow of counters

### Removed

- `axi_channel_compare` was removed in favor of `axi_chan_compare` from the `axi` repository.
- Removed flit generation script `flit_gen.py` including configuration files, since this is now integrated into `floogen` (in conjunction with the `--only-pkg` flag)

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
