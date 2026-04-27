public enum PassManagerError: Error, Sendable, Equatable {
    case walletUnavailable
    case queryFailed(reason: String)
    case invalidPassData(missingFields: [String])
    case serializationFailed(reason: String)
    case deserializationFailed(reason: String)
    case addFailed(reason: String)
    case replaceFailed(reason: String)
    case missingInput(description: String)
}
