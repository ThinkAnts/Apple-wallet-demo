import Foundation

public struct PassData: Sendable, Equatable, Codable {
    public let serialNumber: String
    public let passTypeIdentifier: String
    public let description: String
    public let relevantDate: Date?
    public let barcodePayload: String?
    public let organizationName: String
    public let teamIdentifier: String

    public init(
        serialNumber: String,
        passTypeIdentifier: String,
        description: String,
        relevantDate: Date? = nil,
        barcodePayload: String? = nil,
        organizationName: String,
        teamIdentifier: String
    ) {
        self.serialNumber = serialNumber
        self.passTypeIdentifier = passTypeIdentifier
        self.description = description
        self.relevantDate = relevantDate
        self.barcodePayload = barcodePayload
        self.organizationName = organizationName
        self.teamIdentifier = teamIdentifier
    }
}
