import Foundation

public struct WalletPass: Sendable, Equatable {
    public let serialNumber: String
    public let passTypeIdentifier: String
    public let description: String
    public let relevantDate: Date?
    public let barcodePayload: String?

    public init(
        serialNumber: String,
        passTypeIdentifier: String,
        description: String,
        relevantDate: Date? = nil,
        barcodePayload: String? = nil
    ) {
        self.serialNumber = serialNumber
        self.passTypeIdentifier = passTypeIdentifier
        self.description = description
        self.relevantDate = relevantDate
        self.barcodePayload = barcodePayload
    }
}
