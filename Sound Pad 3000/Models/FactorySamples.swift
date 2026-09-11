import Foundation

struct FactorySample: Equatable, Sendable {
    let padID: Int
    let name: String
    let url: URL
}

enum FactorySamples {
    static let catalog: [(padID: Int, name: String, resource: String)] = [
        (1, "HORN", "01-party-horn"),
        (2, "RIMSHOT", "02-rimshot"),
        (3, "BUZZER", "03-buzzer"),
        (4, "DING", "04-ding"),
        (5, "APPLAUSE", "05-applause"),
        (6, "SAD HORN", "06-sad-horn"),
        (7, "WHOOSH", "07-whoosh"),
        (8, "BOOM", "08-boom"),
    ]

    static func bundled(in bundle: Bundle = .main) -> [FactorySample] {
        catalog.compactMap { item in
            let url = bundle.url(forResource: item.resource, withExtension: "wav", subdirectory: "FactorySounds")
                ?? bundle.url(forResource: item.resource, withExtension: "wav")
            guard let url else { return nil }
            return FactorySample(padID: item.padID, name: item.name, url: url)
        }
    }
}
