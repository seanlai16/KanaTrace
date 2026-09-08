import Foundation

struct StrokeCatalog: Sendable {
    let viewBox: Double
    private let characters: [String: [[StrokePoint]]]

    init(viewBox: Double, characters: [String: [[StrokePoint]]]) {
        self.viewBox = viewBox
        self.characters = characters
    }

    func strokes(for glyph: String) -> [[StrokePoint]] {
        characters[glyph] ?? []
    }

    static func load(from bundle: Bundle) throws -> StrokeCatalog {
        guard let url = bundle.url(forResource: "HiraganaStrokes", withExtension: "json") else {
            throw LoadError.missingFile
        }
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(StrokeFile.self, from: data)
        var map: [String: [[StrokePoint]]] = [:]
        for (glyph, strokes) in file.characters {
            map[glyph] = strokes.map { stroke in
                stroke.compactMap { pair in
                    guard pair.count >= 2 else { return nil }
                    return StrokePoint(x: pair[0], y: pair[1])
                }
            }
        }
        return StrokeCatalog(viewBox: file.viewBox, characters: map)
    }

    enum LoadError: Error {
        case missingFile
    }
}

private struct StrokeFile: Decodable {
    var viewBox: Double
    var characters: [String: [[[Double]]]]
}

enum StrokeResources {
    static var bundle: Bundle { Bundle(for: StrokeResourcesMarker.self) }
}

private final class StrokeResourcesMarker: NSObject {}
