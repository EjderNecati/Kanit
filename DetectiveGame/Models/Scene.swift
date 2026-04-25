import Foundation

struct GameScene: Codable, Identifiable {
    let id: String                      // "scene_001"
    let type: SceneType                 // .narration, .dialogue, .investigation, .accusation
    let background: String              // Gorsel dosya yolu (shared veya case-specific)
    let characterId: String?            // Diyalog sahnelerinde konusan karakter
    let text: String                    // Ana metin
    let choices: [Choice]
    let addEvidence: String?            // Bu sahneye gelince otomatik eklenen delil ID
    let addCharacterNote: String?       // Karakter hakkinda not ekleme
    let requiresEvidence: [String]?     // Bu sahneye girmek icin gereken delil(ler)
    let creditCost: Int?                // Bu sahneye giris kredi maliyeti (nil = ucretsiz)

    /// Bu sahne karakterin menu/hub'i mi?
    /// Hub sahneleri karakter sorgulamasinin baslangic noktasidir.
    /// Bos kaldiginda karakter tukenmis sayilir.
    let isCharacterHub: Bool?

    /// isCharacterHub effective degeri (nil ise false)
    var isHub: Bool { isCharacterHub ?? false }

    enum CodingKeys: String, CodingKey {
        case id, type, background, characterId, text, choices
        case addEvidence, addCharacterNote, requiresEvidence, creditCost
        case isCharacterHub
    }

    init(id: String, type: SceneType, background: String, characterId: String?,
         text: String, choices: [Choice], addEvidence: String?,
         addCharacterNote: String?, requiresEvidence: String?, creditCost: Int?,
         isCharacterHub: Bool? = nil) {
        self.id = id
        self.type = type
        self.background = background
        self.characterId = characterId
        self.text = text
        self.choices = choices
        self.addEvidence = addEvidence
        self.addCharacterNote = addCharacterNote
        self.requiresEvidence = requiresEvidence != nil ? [requiresEvidence!] : nil
        self.creditCost = creditCost
        self.isCharacterHub = isCharacterHub
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(SceneType.self, forKey: .type)
        background = try container.decode(String.self, forKey: .background)
        characterId = try container.decodeIfPresent(String.self, forKey: .characterId)
        text = try container.decode(String.self, forKey: .text)
        choices = try container.decode([Choice].self, forKey: .choices)
        addEvidence = try container.decodeIfPresent(String.self, forKey: .addEvidence)
        addCharacterNote = try container.decodeIfPresent(String.self, forKey: .addCharacterNote)
        creditCost = try container.decodeIfPresent(Int.self, forKey: .creditCost)
        isCharacterHub = try container.decodeIfPresent(Bool.self, forKey: .isCharacterHub)

        // requiresEvidence: hem String hem [String] kabul et
        if let arr = try? container.decodeIfPresent([String].self, forKey: .requiresEvidence) {
            requiresEvidence = arr
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .requiresEvidence) {
            requiresEvidence = [str]
        } else {
            requiresEvidence = nil
        }
    }
}

enum SceneType: String, Codable {
    case narration          // Duz anlatim, arka plan + metin
    case dialogue           // Karakter konusmasi, portre + metin + secenekler
    case investigation      // Olay yeri inceleme
    case accusation         // Final suclama ekrani
    case ending             // Son ekrani
    case flashback          // Geri donus sahnesi (VHS efekti ile)
}
