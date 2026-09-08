import Foundation

struct HiraganaCharacter: Identifiable, Equatable, Hashable, Sendable {
    var glyph: String
    var romaji: String
    var rowID: String

    var id: String { glyph }
}

struct HiraganaRow: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var columns: [HiraganaCharacter?]
    var characters: [HiraganaCharacter] { columns.compactMap { $0 } }
}

enum HiraganaCatalog {
    static let rows: [HiraganaRow] = [
        row("a", "あ行", "あいうえお", ["a", "i", "u", "e", "o"]),
        row("ka", "か行", "かきくけこ", ["ka", "ki", "ku", "ke", "ko"]),
        row("sa", "さ行", "さしすせそ", ["sa", "shi", "su", "se", "so"]),
        row("ta", "た行", "たちつてと", ["ta", "chi", "tsu", "te", "to"]),
        row("na", "な行", "なにぬねの", ["na", "ni", "nu", "ne", "no"]),
        row("ha", "は行", "はひふへほ", ["ha", "hi", "fu", "he", "ho"]),
        row("ma", "ま行", "まみむめも", ["ma", "mi", "mu", "me", "mo"]),
        HiraganaRow(
            id: "ya",
            title: "や行",
            columns: [
                char("や", "ya", "ya"),
                nil,
                char("ゆ", "yu", "ya"),
                nil,
                char("よ", "yo", "ya")
            ]
        ),
        row("ra", "ら行", "らりるれろ", ["ra", "ri", "ru", "re", "ro"]),
        HiraganaRow(
            id: "wa",
            title: "わ行",
            columns: [
                char("わ", "wa", "wa"),
                nil,
                nil,
                nil,
                char("を", "wo", "wa")
            ]
        ),
        HiraganaRow(
            id: "n",
            title: "ん",
            columns: [char("ん", "n", "n"), nil, nil, nil, nil]
        )
    ]

    static let all: [HiraganaCharacter] = rows.flatMap(\.characters)

    static func character(glyph: String) -> HiraganaCharacter? {
        all.first { $0.glyph == glyph }
    }

    private static func char(_ glyph: String, _ romaji: String, _ rowID: String) -> HiraganaCharacter {
        HiraganaCharacter(glyph: glyph, romaji: romaji, rowID: rowID)
    }

    private static func row(_ id: String, _ title: String, _ glyphs: String, _ romaji: [String]) -> HiraganaRow {
        let characters = zip(Array(glyphs).map(String.init), romaji).map { char($0, $1, id) }
        return HiraganaRow(id: id, title: title, columns: characters)
    }
}
