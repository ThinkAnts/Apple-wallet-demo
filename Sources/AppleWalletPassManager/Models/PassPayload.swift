import Foundation

public struct PassPayload: Sendable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }
}
