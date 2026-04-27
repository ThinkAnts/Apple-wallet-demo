import Testing
import Foundation
@testable import AppleWalletPassManager

@Suite("PassSerializer Tests")
struct PassSerializerTests {
    let serializer = PassSerializer()

    @Test("Serialize and deserialize round-trip preserves data")
    func roundTrip() throws {
        let passData = PassData(
            serialNumber: "ABC-123",
            passTypeIdentifier: "pass.com.example.test",
            description: "Test Pass",
            relevantDate: Date(timeIntervalSince1970: 1_700_000_000),
            barcodePayload: "barcode-data-xyz",
            organizationName: "Example Inc",
            teamIdentifier: "TEAM123"
        )

        let payload = try serializer.serialize(passData)
        let restored = try serializer.deserialize(payload)

        #expect(restored == passData)
    }

    @Test("Serialize and deserialize with nil optional fields")
    func roundTripNilOptionals() throws {
        let passData = PassData(
            serialNumber: "SN-001",
            passTypeIdentifier: "pass.com.example",
            description: "Minimal Pass",
            organizationName: "Org",
            teamIdentifier: "TEAM"
        )

        let payload = try serializer.serialize(passData)
        let restored = try serializer.deserialize(payload)

        #expect(restored == passData)
    }

    @Test("Deserialize malformed data throws deserializationFailed")
    func deserializeMalformedData() {
        let badPayload = PassPayload(data: Data("not-valid-json".utf8))

        #expect(throws: PassManagerError.self) {
            try serializer.deserialize(badPayload)
        }
    }

    @Test("Deserialize empty data throws deserializationFailed")
    func deserializeEmptyData() {
        let emptyPayload = PassPayload(data: Data())

        #expect(throws: PassManagerError.self) {
            try serializer.deserialize(emptyPayload)
        }
    }
}
