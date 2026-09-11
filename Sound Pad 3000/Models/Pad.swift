import Foundation

struct Pad: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: Int
    var name: String
    var filename: String?

    var hasAudio: Bool { filename != nil }
}

enum PadStoreError: Error, Equatable {
    case fileTooLarge
    case unsupportedType
    case unplayable
    case copyFailed
}
