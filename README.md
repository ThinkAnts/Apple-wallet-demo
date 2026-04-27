# Apple Wallet Pass Manager

A Swift library and demo iOS app for managing Apple Wallet boarding passes using the PassKit framework. The library provides APIs to create, compare, serialize, and update passes in Apple Wallet.

## Project Structure

```
├── Package.swift                          # Swift Package Manager config
├── Sources/AppleWalletPassManager/        # Library module
│   ├── Models/
│   │   ├── PassData.swift                 # App-side pass data (Codable)
│   │   ├── WalletPass.swift               # Wallet-side pass representation
│   │   ├── PassPayload.swift              # Raw .pkpass data wrapper
│   │   ├── Results.swift                  # AddPassResult, ComparisonResult, SyncResult
│   │   └── PassManagerError.swift         # Typed error cases
│   ├── PassComparator.swift               # Compares WalletPass vs PassData
│   └── PassSerializer.swift               # JSON serialize/deserialize PassData
├── Tests/AppleWalletPassManagerTests/     # Unit tests
├── DemoApp/                               # Standalone Xcode demo app
│   ├── DemoApp.xcodeproj/                 # Xcode project
│   ├── DemoApp/
│   │   ├── DemoApp.swift                  # App entry point
│   │   ├── ContentView.swift              # UI with Create/Update/View buttons
│   │   ├── DemoApp.entitlements           # Pass Type ID entitlement
│   │   ├── BoardingPass.pkpass            # Signed boarding pass
│   │   └── Variant1-10.pkpass             # 10 pre-signed update variants
│   ├── PassAssets/                        # Pass JSON templates and icons
│   ├── sign_pass.sh                       # Script to sign a .pkpass
│   └── generate_variants.sh              # Script to generate update variants
└── .gitignore
```

## Technologies

- Swift 6 with strict concurrency (`Sendable` conformance)
- SwiftUI for the demo app UI
- PassKit framework (`PKPassLibrary`, `PKAddPassesViewController`, `PKPass`)
- Swift Package Manager for dependency management
- SwiftCheck for property-based testing
- OpenSSL for `.pkpass` signing (build-time)
- iOS 16+ deployment target

## Prerequisites

- Xcode 15+ with iOS 16+ SDK
- Apple Developer account
- Pass Type ID certificate (`.p12` file) — see [Setup](#pass-type-id-setup) below
- OpenSSL (included with macOS)

## How to Run

### 1. Run the Library Tests

```bash
xcodebuild test -scheme AppleWalletPassManager \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16'
```

### 2. Run the Demo App

1. Open the Xcode project:
   ```bash
   open DemoApp/DemoApp.xcodeproj
   ```
2. Select an iPhone simulator or a real device from the destination picker
3. Press `Cmd + R` to build and run

### 3. Using the Demo App

- **Create Boarding Pass** — Presents the Apple Wallet add-pass sheet with a boarding pass (ORD → HND, DA 442)
- **Update Boarding Pass** — Silently replaces the pass in Wallet with a random variant (different gate, seat, boarding time)
- **View Boarding Pass** — Opens the pass in the Wallet app

## Pass Type ID Setup

To sign `.pkpass` files, you need a Pass Type ID certificate from Apple:

1. Go to [Apple Developer Portal — Pass Type IDs](https://developer.apple.com/account/resources/identifiers/list/passTypeId)
2. Register a new Pass Type ID (e.g. `pass.com.yourteam.boardingpass`)
3. Create a certificate for that Pass Type ID
4. Export the certificate as a `.p12` file from Keychain Access

## Signing Passes

To re-sign passes with updated data:

1. Edit `DemoApp/PassAssets/pass.json` with your desired boarding pass content
2. Run the signing script:
   ```bash
   bash DemoApp/sign_pass.sh <path-to-your.p12> <p12-password> <output-path.pkpass>
   ```
3. To generate 10 random update variants:
   ```bash
   bash DemoApp/generate_variants.sh <path-to-your.p12> <p12-password>
   ```

## Library Components

| Component | Purpose |
|-----------|---------|
| `PassData` | Codable struct representing app-side pass data |
| `WalletPass` | Struct representing a pass retrieved from Apple Wallet |
| `PassComparator` | Compares `WalletPass` against `PassData`, returns matching or differing fields |
| `PassSerializer` | JSON serialization/deserialization of `PassData` ↔ `PassPayload` |
| `PassManagerError` | Typed errors for all failure cases (wallet unavailable, invalid data, etc.) |

## How Pass Updates Work

Since `.pkpass` files must be cryptographically signed, they cannot be generated on-device at runtime. The demo app bundles 10 pre-signed variants with different boarding details. When you tap "Update", it picks a random variant and calls `PKPassLibrary.replacePass(with:)` to silently update the pass in Wallet.

In a production app, your backend server would sign updated passes and deliver them via Apple's push notification mechanism for passes, allowing Wallet to update automatically without app involvement.

## License

This project is for demonstration purposes.
