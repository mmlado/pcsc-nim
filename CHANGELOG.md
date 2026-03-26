# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-03-26

### Fixed

- Linux 64-bit type fix: `DWORD`/`LONG` corrected to pointer-sized `uint`/`int`, fixing card handle corruption and error code mismatches.

## [0.1.0] - 2025-08-27

### Added

- Core FFI bindings to PC/SC (SCardEstablishContext, SCardListReaders, SCardConnect, SCardDisconnect, SCardTransmit).
- Connect/disconnect with T=0/T=1 negotiation.
- Transmit (raw APDU bytes).
- SW helper to get SW1/SW2; util.prettyHex for printing responses.
- Error handling (PcscError) with raiseIfError wrappers.
- Examples: list_readers.nim, transmit_apdu.nim.
- Unit tests for hex utilities.

[unreleased]: https://github.com/mmlado/pcsc-nim/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/mmlado/pcsc-nim/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/mmlado/pcsc-nim/releases/tag/v0.1.0

