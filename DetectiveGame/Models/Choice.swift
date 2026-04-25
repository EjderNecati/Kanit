import Foundation

struct Choice: Codable, Identifiable {
    let id: String
    let text: String                    // Buton metni
    let nextSceneId: String             // Hedef sahne
    let creditCost: Int                 // 0 = ucretsiz, 1+ = kredi gerekli
    let isHidden: Bool                  // Belirli bir delil olmadan gizli mi?
    let requiredEvidenceId: String?     // Bu secenegin gorunmesi icin gereken delil

    // Yeni: Stateful diyalog sistemi alanlari (hepsi optional, eski JSON bozulmaz)

    /// Bu secenek bir kez alindiginda tuketilsin mi? Default: true
    /// Tuketilmis secenekler bir daha hic gosterilmez.
    let consumable: Bool?

    /// Gorunmesi icin bu mekan(lar)in ziyaret edilmis olmasi gerekir
    let requiresLocationVisited: [String]?

    /// Gorunmesi icin bu mekan(lar)in HENUZ ziyaret edilmemis olmasi gerekir
    /// (ornek: karakterde "eczaneyi kontrol edelim" secenegi, eczane zaten ziyaret edildiyse cikmasin)
    let requiresLocationNotVisited: [String]?

    /// Bu mekan ziyaret edilirse bu secenek otomatik tuketilmis sayilir
    /// (ornek: eczaneye gidilince, Derya'daki "ona eczaneyi sor" secenegi kilitlenir)
    let consumesOnLocationVisit: [String]?

    /// consumable'in effective degeri (nil ise default true)
    var isConsumable: Bool { consumable ?? true }

    enum CodingKeys: String, CodingKey {
        case id, text, nextSceneId, creditCost, isHidden, requiredEvidenceId
        case consumable, requiresLocationVisited, requiresLocationNotVisited, consumesOnLocationVisit
    }

    /// Convenience init (kod icinde synthetic choice olusturmak icin)
    init(
        id: String,
        text: String,
        nextSceneId: String,
        creditCost: Int = 0,
        isHidden: Bool = false,
        requiredEvidenceId: String? = nil,
        consumable: Bool? = nil,
        requiresLocationVisited: [String]? = nil,
        requiresLocationNotVisited: [String]? = nil,
        consumesOnLocationVisit: [String]? = nil
    ) {
        self.id = id
        self.text = text
        self.nextSceneId = nextSceneId
        self.creditCost = creditCost
        self.isHidden = isHidden
        self.requiredEvidenceId = requiredEvidenceId
        self.consumable = consumable
        self.requiresLocationVisited = requiresLocationVisited
        self.requiresLocationNotVisited = requiresLocationNotVisited
        self.consumesOnLocationVisit = consumesOnLocationVisit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        nextSceneId = try c.decode(String.self, forKey: .nextSceneId)
        creditCost = try c.decodeIfPresent(Int.self, forKey: .creditCost) ?? 0
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        requiredEvidenceId = try c.decodeIfPresent(String.self, forKey: .requiredEvidenceId)
        consumable = try c.decodeIfPresent(Bool.self, forKey: .consumable)
        requiresLocationVisited = try c.decodeIfPresent([String].self, forKey: .requiresLocationVisited)
        requiresLocationNotVisited = try c.decodeIfPresent([String].self, forKey: .requiresLocationNotVisited)
        consumesOnLocationVisit = try c.decodeIfPresent([String].self, forKey: .consumesOnLocationVisit)
    }
}
