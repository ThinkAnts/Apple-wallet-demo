# Implementation Plan: Apple Wallet Pass Manager

## Overview

Incrementally build the Apple Wallet Pass Manager Swift module, starting with data models and pure logic (comparator, serializer), then the PassKit service abstraction, and finally the orchestrating PassManager. Each step wires into the previous one. Property-based tests use SwiftCheck.

## Tasks

- [x] 1. Set up package structure and define data models
  - [x] 1.1 Configure Package.swift with iOS platform, PassKit dependency, and SwiftCheck test dependency
    - Add `platforms: [.iOS(.v16)]` to Package.swift
    - Add a library target `AppleWalletPassManager` under `Sources/AppleWalletPassManager`
    - Add a test target `AppleWalletPassManagerTests` under `Tests/AppleWalletPassManagerTests`
    - Add SwiftCheck as a package dependency for the test target
    - _Requirements: 1.1_

  - [x] 1.2 Create data model types
    - Create `Sources/AppleWalletPassManager/Models/PassData.swift` with the `PassData` struct (Sendable, Equatable, Codable)
    - Create `Sources/AppleWalletPassManager/Models/WalletPass.swift` with the `WalletPass` struct (Sendable, Equatable)
    - Create `Sources/AppleWalletPassManager/Models/PassPayload.swift` with the `PassPayload` struct (Sendable)
    - Create `Sources/AppleWalletPassManager/Models/Results.swift` with `AddPassResult`, `ComparisonResult`, and `SyncResult` enums
    - Create `Sources/AppleWalletPassManager/Models/PassManagerError.swift` with the `PassManagerError` enum (Error, Sendable, Equatable)
    - _Requirements: 1.3, 2.2, 2.4, 3.5, 3.6, 4.5, 5.5, 6.4_

- [x] 2. Implement PassComparator
  - [x] 2.1 Create PassComparator struct
    - Create `Sources/AppleWalletPassManager/PassComparator.swift`
    - Implement `compare(walletPass:passData:)` returning `ComparisonResult`
    - Compare fields: serialNumber, description, relevantDate, barcodePayload
    - Return `.equivalent` when all fields match, `.different(fields:)` with differing field names otherwise
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ]* 2.2 Write property test: Identical data yields equivalence
    - **Property 2: Identical data yields equivalence**
    - Generate random `PassData`, construct a matching `WalletPass`, assert comparator returns `.equivalent`
    - **Validates: Requirements 4.1, 4.2**

  - [ ]* 2.3 Write property test: Field change detection
    - **Property 3: Field change detection**
    - Generate random `PassData`, mutate exactly one comparison field in the corresponding `WalletPass`, assert comparator returns `.different(fields:)` containing exactly that field
    - **Validates: Requirements 4.3, 4.4**

- [x] 3. Implement PassSerializer
  - [x] 3.1 Create PassSerializer struct
    - Create `Sources/AppleWalletPassManager/PassSerializer.swift`
    - Implement `serialize(_ passData: PassData) throws -> PassPayload` using JSON encoding
    - Implement `deserialize(_ payload: PassPayload) throws -> PassData` using JSON decoding
    - Throw `PassManagerError.serializationFailed` or `.deserializationFailed` with descriptive reasons on failure
    - _Requirements: 6.1, 6.2, 6.4_

  - [ ]* 3.2 Write property test: Serialization round-trip
    - **Property 4: Serialization round-trip**
    - Generate random valid `PassData`, serialize then deserialize, assert equality with original
    - **Validates: Requirements 6.1, 6.2, 6.3**

  - [ ]* 3.3 Write property test: Malformed payload produces descriptive error
    - **Property 7: Malformed payload produces descriptive error**
    - Generate random `Data` that is not valid serialized `PassData`, assert `.deserializationFailed` with non-empty reason
    - **Validates: Requirements 6.4**

- [x] 4. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement PassKitService protocol and LivePassKitService
  - [ ] 5.1 Create PassKitService protocol
    - Create `Sources/AppleWalletPassManager/PassKitService.swift`
    - Define the `PassKitService` protocol with `isWalletAvailable()`, `passes(ofType:)`, `addPass(_:)`, and `replacePass(existingPass:with:)` methods
    - Protocol must conform to `Sendable`
    - _Requirements: 1.1, 1.2, 2.1, 3.2, 5.3_

  - [ ] 5.2 Create MockPassKitService for testing
    - Create `Tests/AppleWalletPassManagerTests/MockPassKitService.swift`
    - Implement a configurable mock that conforms to `PassKitService`
    - Support configurable return values and thrown errors for each method
    - _Requirements: 1.2, 1.3, 2.1, 2.4, 3.3, 3.4, 3.6, 5.4, 5.5_

  - [ ] 5.3 Create LivePassKitService
    - Create `Sources/AppleWalletPassManager/LivePassKitService.swift`
    - Implement `PassKitService` using `PKPassLibrary` and `PKAddPassesViewController`
    - `isWalletAvailable()` checks `PKPassLibrary.isPassLibraryAvailable()`
    - `passes(ofType:)` queries `PKPassLibrary` and maps results to `WalletPass`
    - `addPass(_:)` presents `PKAddPassesViewController` and returns `AddPassResult`
    - `replacePass(existingPass:with:)` calls `PKPassLibrary.replacePass(with:)`
    - Wrap PassKit errors into `PassManagerError` cases
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 3.2, 3.3, 3.4, 3.6, 5.3, 5.4, 5.5_

- [ ] 6. Implement PassManager orchestrator
  - [ ] 6.1 Create PassManager struct
    - Create `Sources/AppleWalletPassManager/PassManager.swift`
    - Initialize with `PassKitService`, `PassComparator`, and `PassSerializer`
    - Implement `existingPasses(forType:)` — delegates to service, returns `[WalletPass]`
    - Implement `addPass(from:)` — validates PassData, serializes, calls service `addPass`, returns `AddPassResult`
    - Implement `syncPass(walletPass:with:)` — compares, routes to update or add-new based on serial number match, returns `SyncResult`
    - Guard wallet availability before operations, throw `.walletUnavailable` if unsupported
    - Validate PassData required fields (serialNumber, passTypeIdentifier, organizationName, teamIdentifier), throw `.invalidPassData(missingFields:)` for empty fields
    - _Requirements: 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.3, 3.4, 3.5, 5.1, 5.2, 5.3, 5.4, 5.6_

  - [ ]* 6.2 Write property test: Query returns only matching passes
    - **Property 1: Query returns only matching passes**
    - Generate random sets of `WalletPass` with varied `passTypeIdentifier` values and a random query identifier, configure mock to return them, assert filtered result contains exactly the matching passes
    - **Validates: Requirements 2.1, 2.2, 2.3**

  - [ ]* 6.3 Write property test: Validation rejects incomplete PassData
    - **Property 5: Validation rejects incomplete PassData**
    - Generate `PassData` with random subsets of required fields set to empty strings, assert `.invalidPassData(missingFields:)` contains exactly those field names
    - **Validates: Requirements 3.5**

  - [ ]* 6.4 Write property test: Sync routing correctness
    - **Property 6: Sync routing correctness**
    - Generate random `WalletPass`/`PassData` pairs with matching or non-matching serial numbers and differing fields, assert correct routing (update vs. add-new)
    - **Validates: Requirements 5.1, 5.6**

- [ ] 7. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Unit tests for PassManager flows
  - [ ] 8.1 Write unit tests for wallet availability and query flows
    - Test: wallet unavailable returns `.walletUnavailable` error
    - Test: query with no matches returns empty list
    - Test: query error propagation returns `.queryFailed`
    - _Requirements: 1.2, 1.3, 2.2, 2.3, 2.4_

  - [ ] 8.2 Write unit tests for add-pass flows
    - Test: add pass with user confirmation returns `.added`
    - Test: add pass with user cancellation returns `.cancelled`
    - Test: add pass failure returns `.addFailed`
    - Test: add pass with invalid PassData returns `.invalidPassData`
    - _Requirements: 3.1, 3.3, 3.4, 3.5, 3.6_

  - [ ] 8.3 Write unit tests for sync and update flows
    - Test: sync with equivalent passes returns `.alreadyUpToDate`
    - Test: sync with differing passes and matching serial returns `.updated`
    - Test: sync with non-matching serial routes to add-new flow
    - Test: replace pass failure returns `.replaceFailed`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 9. Wire public API and export module
  - [ ] 9.1 Create public module entry point
    - Create `Sources/AppleWalletPassManager/AppleWalletPassManager.swift` as the module's public API surface
    - Re-export all public types: `PassManager`, `PassData`, `WalletPass`, `PassPayload`, `AddPassResult`, `ComparisonResult`, `SyncResult`, `PassManagerError`, `PassKitService`
    - Add a convenience factory method to create a `PassManager` with `LivePassKitService` defaults
    - _Requirements: 1.1, 1.2_

- [ ] 10. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use SwiftCheck with a minimum of 100 iterations per property
- The MockPassKitService enables all unit and property tests to run without a real device or wallet
- Checkpoints ensure incremental validation throughout implementation
