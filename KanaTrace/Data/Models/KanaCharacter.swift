import Foundation

enum KanaScript: String, CaseIterable, Identifiable, Sendable {
    case hiragana
    case katakana

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hiragana: return "Hiragana"
        case .katakana: return "Katakana"
        }
    }
}

struct KanaCharacter: Identifiable, Equatable, Hashable, Sendable {
    var glyph: String
    var romaji: String
    var rowID: String
    var script: KanaScript

    var id: String { glyph }
}

struct KanaRow: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var columns: [KanaCharacter?]
    var characters: [KanaCharacter] { columns.compactMap { $0 } }
}

enum KanaCatalog {
    static func rows(for script: KanaScript) -> [KanaRow] {
        switch script {
        case .hiragana: return hiraganaRows
        case .katakana: return katakanaRows
        }
    }

    static func all(for script: KanaScript) -> [KanaCharacter] {
        rows(for: script).flatMap(\.characters)
    }

    static func character(glyph: String, script: KanaScript) -> KanaCharacter? {
        all(for: script).first { $0.glyph == glyph }
    }

    private static let romajiFive = ["a", "i", "u", "e", "o"]
    private static let romajiK = ["ka", "ki", "ku", "ke", "ko"]
    private static let romajiS = ["sa", "shi", "su", "se", "so"]
    private static let romajiT = ["ta", "chi", "tsu", "te", "to"]
    private static let romajiN = ["na", "ni", "nu", "ne", "no"]
    private static let romajiH = ["ha", "hi", "fu", "he", "ho"]
    private static let romajiM = ["ma", "mi", "mu", "me", "mo"]
    private static let romajiR = ["ra", "ri", "ru", "re", "ro"]

    private static let hiraganaRows: [KanaRow] = [
        five("a", "あ行", "あいうえお", romajiFive, .hiragana),
        five("ka", "か行", "かきくけこ", romajiK, .hiragana),
        five("sa", "さ行", "さしすせそ", romajiS, .hiragana),
        five("ta", "た行", "たちつてと", romajiT, .hiragana),
        five("na", "な行", "なにぬねの", romajiN, .hiragana),
        five("ha", "は行", "はひふへほ", romajiH, .hiragana),
        five("ma", "ま行", "まみむめも", romajiM, .hiragana),
        sparse(
            "ya",
            "や行",
            [char("や", "ya", "ya", .hiragana), nil, char("ゆ", "yu", "ya", .hiragana), nil, char("よ", "yo", "ya", .hiragana)]
        ),
        five("ra", "ら行", "らりるれろ", romajiR, .hiragana),
        sparse(
            "wa",
            "わ行",
            [char("わ", "wa", "wa", .hiragana), nil, nil, nil, char("を", "wo", "wa", .hiragana)]
        ),
        sparse("n", "ん", [char("ん", "n", "n", .hiragana), nil, nil, nil, nil])
    ]

    private static let katakanaRows: [KanaRow] = [
        five("a", "ア行", "アイウエオ", romajiFive, .katakana),
        five("ka", "カ行", "カキクケコ", romajiK, .katakana),
        five("sa", "サ行", "サシスセソ", romajiS, .katakana),
        five("ta", "タ行", "タチツテト", romajiT, .katakana),
        five("na", "ナ行", "ナニヌネノ", romajiN, .katakana),
        five("ha", "ハ行", "ハヒフヘホ", romajiH, .katakana),
        five("ma", "マ行", "マミムメモ", romajiM, .katakana),
        sparse(
            "ya",
            "ヤ行",
            [char("ヤ", "ya", "ya", .katakana), nil, char("ユ", "yu", "ya", .katakana), nil, char("ヨ", "yo", "ya", .katakana)]
        ),
        five("ra", "ラ行", "ラリルレロ", romajiR, .katakana),
        sparse(
            "wa",
            "ワ行",
            [char("ワ", "wa", "wa", .katakana), nil, nil, nil, char("ヲ", "wo", "wa", .katakana)]
        ),
        sparse("n", "ン", [char("ン", "n", "n", .katakana), nil, nil, nil, nil])
    ]

    private static func char(_ glyph: String, _ romaji: String, _ rowID: String, _ script: KanaScript) -> KanaCharacter {
        KanaCharacter(glyph: glyph, romaji: romaji, rowID: rowID, script: script)
    }

    private static func five(
        _ id: String,
        _ title: String,
        _ glyphs: String,
        _ romaji: [String],
        _ script: KanaScript
    ) -> KanaRow {
        let columns = zip(Array(glyphs).map(String.init), romaji).map { char($0, $1, id, script) }
        return KanaRow(id: id, title: title, columns: columns)
    }

    private static func sparse(_ id: String, _ title: String, _ columns: [KanaCharacter?]) -> KanaRow {
        KanaRow(id: id, title: title, columns: columns)
    }
}
