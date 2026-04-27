import Foundation

public struct PassSerializer: Sendable {
    public init() {}

    /// Serialize PassData into a PassPayload using JSON encoding.
    public func serialize(_ passData: PassData) throws -> PassPayload {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(passData)
            return PassPayload(data: data)
        } catch {
            throw PassManagerError.serializationFailed(reason: "Failed to serialize PassData: \(error.localizedDescription)")
        }
    }

    /// Deserialize a PassPayload back into PassData using JSON decoding.
    public func deserialize(_ payload: PassPayload) throws -> PassData {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(PassData.self, from: payload.data)
        } catch {
            throw PassManagerError.deserializationFailed(reason: "Failed to deserialize PassPayload: \(error.localizedDescription)")
        }
    }
}
