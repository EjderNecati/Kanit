import Foundation

struct Case: Codable, Identifiable {
    let id: String                      // "istanbul-001"
    let title: String                   // "Karanlik Sular"
    let subtitle: String                // "Istanbul, 2024"
    let city: String
    let description: String             // Kisa tanitim (vaka secim ekraninda gorunur)
    let coverImage: String              // Kapak gorseli dosya adi
    let difficulty: Int                 // 1-5
    let isPremium: Bool                 // Ucretli mi?
    let evidence: [Evidence]
    let scenes: [GameScene]
    let characters: [Character]
    let endings: [Ending]
    let hqLocations: [HQLocation]?      // Karargah lokasyon kisayollari
    let phoneData: PhoneData?           // Telefon kayitlari
    let cameraData: CameraData?         // Guvenlik kamerasi
    let labAnalyses: [LabAnalysis]?     // Laboratuvar analizleri
    let contradictions: [Contradiction]? // Celiskiler
    let flashbackTriggers: [FlashbackTrigger]? // Flashback tetikleyicileri
    let newspaperArticles: [NewspaperArticle]? // Gazete haberleri
    let suspectNetwork: SuspectNetwork? // Supheli agi
    let pressEvents: [PressEvent]?      // Basin olaylari
    let timedEvents: [TimedEvent]?      // Zamanli olaylar
    let suspectAvailability: [String: SuspectSchedule]? // Supheli musaitlik
    let achievements: [AchievementDef]? // Basarimlar
    let evidenceReactions: [EvidenceReactionDef]? // Delil tepkileri
    let microExpressions: [MicroExpressionDef]? // Mikro ifadeler
    let coCulprits: [String]?           // Birden fazla suclu olan vakalar icin (hepsi secilmeli)
}

// MARK: - Zamanli Olay
struct TimedEvent: Codable, Identifiable {
    let id: String
    let triggerAfterScenes: Int
    let type: String                     // "unlock_scene", "unlock_evidence", "notification"
    let sceneId: String?                 // Acilacak sahne
    let evidenceId: String?              // Acilacak delil
    let message: String?                 // Bildirim mesaji

    enum CodingKeys: String, CodingKey {
        case id, triggerAfterScenes, type, sceneId, evidenceId, message
        case triggerDay, triggerHour // legacy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        sceneId = try c.decodeIfPresent(String.self, forKey: .sceneId)
        evidenceId = try c.decodeIfPresent(String.self, forKey: .evidenceId)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        if let t = try c.decodeIfPresent(Int.self, forKey: .triggerAfterScenes) {
            triggerAfterScenes = t
        } else {
            let day = (try c.decodeIfPresent(Int.self, forKey: .triggerDay)) ?? 1
            let hour = (try c.decodeIfPresent(Int.self, forKey: .triggerHour)) ?? 0
            triggerAfterScenes = (day - 1) * 7 + hour / 4
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(triggerAfterScenes, forKey: .triggerAfterScenes)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(sceneId, forKey: .sceneId)
        try c.encodeIfPresent(evidenceId, forKey: .evidenceId)
        try c.encodeIfPresent(message, forKey: .message)
    }
}

// MARK: - Basarim Tanimi (JSON'dan)
struct AchievementDef: Codable, Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let condition: String       // "evidence_count_1", "perfect_ending", "all_suspects_interviewed"
}

// MARK: - Delil Tepkisi Tanimi (JSON'dan)
struct EvidenceReactionDef: Codable {
    let characterId: String
    let evidenceId: String
    let reaction: String        // "nervous", "angry", "surprised", "calm"
    let dialogue: String
    let note: String
}

// MARK: - Mikro Ifade Tanimi (JSON'dan)
struct MicroExpressionDef: Codable, Identifiable {
    let id: String
    let characterId: String
    let triggerScene: String
    let displayText: String
    let timeWindow: Double      // saniye
}

// MARK: - Supheli Musaitlik
struct SuspectSchedule: Codable {
    let availableHours: [Int]
    let unavailableMsg: String
}

// MARK: - HQ Lokasyon Kisayolu
struct HQLocation: Codable {
    let sceneId: String                 // "scene_002"
    let label: String                   // "Olay Yeri"
    let icon: String                    // SF Symbol adi: "house.fill"
}

// MARK: - Telefon Verileri
struct PhoneData: Codable {
    let owner: String
    let messages: [PhoneThread]
    let callLog: [CallEntry]
}

struct PhoneThread: Codable, Identifiable {
    let id: String
    let contact: String
    let contactId: String
    let time: String
    let date: String
    let messages: [PhoneMessage]
}

struct PhoneMessage: Codable {
    let from: String
    let text: String
    let time: String
}

struct CallEntry: Codable {
    let contact: String
    let time: String
    let duration: String
    let type: String              // "incoming", "outgoing", "missed"
    let date: String
}

// MARK: - Guvenlik Kamerasi
struct CameraData: Codable {
    let location: String
    let date: String
    let events: [CameraEvent]
}

struct CameraEvent: Codable, Identifiable {
    var id: String { "\(time)_\(label)" }
    let time: String
    let position: Int             // 0-100 timeline pozisyonu
    let label: String
    let detail: String
    let isKey: Bool
}

// MARK: - Laboratuvar Analizi
struct LabAnalysis: Codable, Identifiable {
    let id: String
    let title: String
    let sampleIcon: String        // SF Symbol adi
    let steps: [String]
    let duration: Int             // milisaniye
    let resultTitle: String
    let resultText: String
    let resultNote: String        // GameState'e eklenecek not
}

// MARK: - Celiskiler
struct Contradiction: Codable, Identifiable {
    let id: String
    let requires: [String]        // Gerekli delil ID'leri
    let statement1: ContraStatement
    let statement2: ContraStatement
    let result: ContraResult
}

struct ContraStatement: Codable {
    let source: String            // Karakter veya delil ID
    let text: String
}

struct ContraResult: Codable {
    let text: String
}

// MARK: - Flashback Tetikleyici
struct FlashbackTrigger: Codable, Identifiable {
    let id: String
    let sceneId: String
    let requires: [String]        // Gerekli delil ID'leri
    let creditCost: Int?
}

// MARK: - Gazete Haberleri
struct NewspaperArticle: Codable, Identifiable {
    let id: String
    let requires: [String]?       // Gerekli delil ID'leri (nil = her zaman gorunur)
    let headline: String
    let subheadline: String
    let body: String
    let source: String            // "Hurriyet", "Le Monde" vb.
}

// MARK: - Supheli Agi
struct SuspectNetwork: Codable {
    let nodes: [NetworkNode]
    let connections: [NetworkConnection]
}

struct NetworkNode: Codable, Identifiable {
    let id: String
    let label: String
    let type: String              // "victim", "suspect", "npc", "arrested"
}

struct NetworkConnection: Codable, Identifiable {
    var id: String { "\(from)_\(to)" }
    let from: String
    let to: String
    let type: String              // "family", "business", "romantic", "suspicious", "rivalry"
    let label: String
    let strength: Int             // 1-3
    let requires: [String]        // Gerekli delil ID'leri (bos = bastan gorunur)
}
