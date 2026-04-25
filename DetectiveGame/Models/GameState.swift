import Foundation
import SwiftUI

// MARK: - Oyuncu Notu

struct PlayerNote: Codable, Identifiable {
    let id: UUID
    let text: String
    let sceneId: String?
    let timestamp: Date

    init(text: String, sceneId: String? = nil) {
        self.id = UUID()
        self.text = text
        self.sceneId = sceneId
        self.timestamp = Date()
    }
}

// MARK: - Itibar Logu

struct ReputationEntry: Codable {
    let event: String
    let change: Int
    let newValue: Int
}

// MARK: - Itibar Seviyesi

struct ReputationLevel {
    let min: Int
    let max: Int
    let title: String
    let titleEN: String
    let icon: String
    let color: Color

    static let levels: [ReputationLevel] = [
        ReputationLevel(min: 0,  max: 19, title: "Beceriksiz Dedektif", titleEN: "Incompetent Detective", icon: "😤", color: Color(hex: "E74C3C")),
        ReputationLevel(min: 20, max: 39, title: "Acemi Dedektif",      titleEN: "Rookie Detective",       icon: "😐", color: Color(hex: "E67E22")),
        ReputationLevel(min: 40, max: 59, title: "Dedektif",            titleEN: "Detective",              icon: "🕵️", color: Color(hex: "F1C40F")),
        ReputationLevel(min: 60, max: 79, title: "Kıdemli Dedektif",    titleEN: "Senior Detective",      icon: "⭐", color: Color(hex: "2ECC71")),
        ReputationLevel(min: 80, max: 100, title: "Efsane Dedektif",    titleEN: "Legendary Detective",   icon: "👑", color: Color(hex: "C4A35A"))
    ]

    static func level(for reputation: Int) -> ReputationLevel {
        levels.first { reputation >= $0.min && reputation <= $0.max } ?? levels[2]
    }
}

// MARK: - Oyun Durumu

class GameState: ObservableObject, Codable {
    @Published var currentCaseId: String
    @Published var currentSceneId: String
    @Published var collectedEvidence: [String]
    @Published var visitedScenes: [String]
    @Published var characterNotes: [String: [String]]
    @Published var choiceHistory: [String]
    @Published var discoveredContradictions: [String] = []
    @Published var completedLabAnalyses: [String] = []
    @Published var triggeredFlashbacks: [String] = []
    @Published var playerNotes: [PlayerNote] = []
    @Published var shownEvidence: [String: [String]] = [:]

    // Itibar sistemi
    @Published var reputation: Int = 50
    @Published var reputationLog: [ReputationEntry] = []

    // Basin olaylari
    @Published var answeredPress: [String] = []

    // Zamanli olaylar
    @Published var triggeredTimedEvents: [String] = []

    // Stateful diyalog sistemi
    /// Tuketilmis choice id'leri. Bir daha hic gosterilmez.
    @Published var consumedChoices: Set<String> = []
    /// Karakter id -> son bulundugu diyalog sahnesi id'si
    @Published var characterLastScene: [String: String] = [:]
    /// Sorgusu bitmis karakterler
    @Published var exhaustedCharacters: Set<String> = []

    init(caseId: String, startSceneId: String) {
        self.currentCaseId = caseId
        self.currentSceneId = startSceneId
        self.collectedEvidence = []
        self.visitedScenes = [startSceneId]
        self.characterNotes = [:]
        self.choiceHistory = []
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case currentCaseId, currentSceneId, collectedEvidence
        case visitedScenes, characterNotes, choiceHistory
        case discoveredContradictions, completedLabAnalyses, triggeredFlashbacks
        case playerNotes, shownEvidence
        case reputation, reputationLog
        case answeredPress, triggeredTimedEvents
        case consumedChoices, characterLastScene, exhaustedCharacters
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentCaseId = try container.decode(String.self, forKey: .currentCaseId)
        currentSceneId = try container.decode(String.self, forKey: .currentSceneId)
        collectedEvidence = try container.decode([String].self, forKey: .collectedEvidence)
        visitedScenes = try container.decode([String].self, forKey: .visitedScenes)
        characterNotes = try container.decode([String: [String]].self, forKey: .characterNotes)
        choiceHistory = try container.decode([String].self, forKey: .choiceHistory)
        discoveredContradictions = try container.decodeIfPresent([String].self, forKey: .discoveredContradictions) ?? []
        completedLabAnalyses = try container.decodeIfPresent([String].self, forKey: .completedLabAnalyses) ?? []
        triggeredFlashbacks = try container.decodeIfPresent([String].self, forKey: .triggeredFlashbacks) ?? []
        playerNotes = try container.decodeIfPresent([PlayerNote].self, forKey: .playerNotes) ?? []
        shownEvidence = try container.decodeIfPresent([String: [String]].self, forKey: .shownEvidence) ?? [:]
        reputation = try container.decodeIfPresent(Int.self, forKey: .reputation) ?? 50
        reputationLog = try container.decodeIfPresent([ReputationEntry].self, forKey: .reputationLog) ?? []
        answeredPress = try container.decodeIfPresent([String].self, forKey: .answeredPress) ?? []
        triggeredTimedEvents = try container.decodeIfPresent([String].self, forKey: .triggeredTimedEvents) ?? []
        // Yeni alanlar: eski save'ler icin optional
        let consumedArr = try container.decodeIfPresent([String].self, forKey: .consumedChoices) ?? []
        consumedChoices = Set(consumedArr)
        characterLastScene = try container.decodeIfPresent([String: String].self, forKey: .characterLastScene) ?? [:]
        let exhaustedArr = try container.decodeIfPresent([String].self, forKey: .exhaustedCharacters) ?? []
        exhaustedCharacters = Set(exhaustedArr)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentCaseId, forKey: .currentCaseId)
        try container.encode(currentSceneId, forKey: .currentSceneId)
        try container.encode(collectedEvidence, forKey: .collectedEvidence)
        try container.encode(visitedScenes, forKey: .visitedScenes)
        try container.encode(characterNotes, forKey: .characterNotes)
        try container.encode(choiceHistory, forKey: .choiceHistory)
        try container.encode(discoveredContradictions, forKey: .discoveredContradictions)
        try container.encode(completedLabAnalyses, forKey: .completedLabAnalyses)
        try container.encode(triggeredFlashbacks, forKey: .triggeredFlashbacks)
        try container.encode(playerNotes, forKey: .playerNotes)
        try container.encode(shownEvidence, forKey: .shownEvidence)
        try container.encode(reputation, forKey: .reputation)
        try container.encode(reputationLog, forKey: .reputationLog)
        try container.encode(answeredPress, forKey: .answeredPress)
        try container.encode(triggeredTimedEvents, forKey: .triggeredTimedEvents)
        try container.encode(Array(consumedChoices), forKey: .consumedChoices)
        try container.encode(characterLastScene, forKey: .characterLastScene)
        try container.encode(Array(exhaustedCharacters), forKey: .exhaustedCharacters)
    }

    // MARK: - Helpers

    func hasEvidence(_ evidenceId: String) -> Bool {
        collectedEvidence.contains(evidenceId)
    }

    func addEvidence(_ evidenceId: String) {
        guard !collectedEvidence.contains(evidenceId) else { return }
        collectedEvidence.append(evidenceId)
    }

    func addNote(for characterId: String, note: String) {
        if characterNotes[characterId] == nil {
            characterNotes[characterId] = []
        }
        characterNotes[characterId]?.append(note)
    }

    func addPlayerNote(_ text: String, sceneId: String? = nil) {
        playerNotes.append(PlayerNote(text: text, sceneId: sceneId))
    }

    func hasShownEvidence(_ evidenceId: String, to characterId: String) -> Bool {
        shownEvidence[characterId]?.contains(evidenceId) ?? false
    }

    func markEvidenceShown(_ evidenceId: String, to characterId: String) {
        if shownEvidence[characterId] == nil {
            shownEvidence[characterId] = []
        }
        shownEvidence[characterId]?.append(evidenceId)
    }

    // MARK: - Itibar

    func changeReputation(event: String, amount: Int) {
        let oldRep = reputation
        reputation = max(0, min(100, reputation + amount))
        if reputation != oldRep {
            reputationLog.append(ReputationEntry(event: event, change: amount, newValue: reputation))
        }
    }

    var reputationLevel: ReputationLevel {
        ReputationLevel.level(for: reputation)
    }

}
