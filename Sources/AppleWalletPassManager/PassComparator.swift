import Foundation

public struct PassComparator: Sendable {
    public init() {}

    /// Compare a wallet pass against app pass data.
    /// Returns `.equivalent` if all compared fields match,
    /// or `.different(fields:)` with the names of differing fields.
    public func compare(walletPass: WalletPass, passData: PassData) -> ComparisonResult {
        var differingFields: [String] = []

        if walletPass.serialNumber != passData.serialNumber {
            differingFields.append("serialNumber")
        }
        if walletPass.description != passData.description {
            differingFields.append("description")
        }
        if walletPass.relevantDate != passData.relevantDate {
            differingFields.append("relevantDate")
        }
        if walletPass.barcodePayload != passData.barcodePayload {
            differingFields.append("barcodePayload")
        }

        if differingFields.isEmpty {
            return .equivalent
        } else {
            return .different(fields: differingFields)
        }
    }
}
