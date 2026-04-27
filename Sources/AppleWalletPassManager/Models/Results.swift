public enum AddPassResult: Sendable, Equatable {
    case added
    case cancelled
}

public enum ComparisonResult: Sendable, Equatable {
    case equivalent
    case different(fields: [String])
}

public enum SyncResult: Sendable, Equatable {
    case alreadyUpToDate
    case updated
    case addedAsNew(AddPassResult)
}
