import Foundation

struct Character: Codable, Identifiable {
    let id: String                      // "suspect_elif"
    let name: String
    let age: Int
    let occupation: String
    let relationToVictim: String
    let portraitImage: String
    let isSuspect: Bool
    let alibi: String                   // Ilk ifade
    /// Opsiyonel: karaktere ozel "tukenmis" sahne metni.
    /// Koma, olmus, kaybolmus gibi karakterler icin default "pencereye dondu" metni uygun degil.
    /// Set edildiyse default metin yerine bu kullanilir.
    let exhaustedText: String?

    enum CodingKeys: String, CodingKey {
        case id, name, age, occupation, relationToVictim, portraitImage, isSuspect, alibi
        case exhaustedText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        age = try c.decode(Int.self, forKey: .age)
        occupation = try c.decode(String.self, forKey: .occupation)
        relationToVictim = try c.decode(String.self, forKey: .relationToVictim)
        portraitImage = try c.decode(String.self, forKey: .portraitImage)
        isSuspect = try c.decode(Bool.self, forKey: .isSuspect)
        alibi = try c.decode(String.self, forKey: .alibi)
        exhaustedText = try c.decodeIfPresent(String.self, forKey: .exhaustedText)
    }
}
