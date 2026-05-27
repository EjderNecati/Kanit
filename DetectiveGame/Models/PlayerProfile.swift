import Foundation
import SwiftUI

class PlayerProfile: ObservableObject, Codable {
    @Published var credits: Int
    @Published var unlockedCases: [String]
    @Published var completedCases: [String: String]
    @Published var totalCasesSolved: Int
    @Published var purchasedCases: [String]             // Satin alinan premium vakalar (bir kez al, hep oyna)
    @Published var accusationHistory: [String: Int]     // caseId -> suclama sayisi
    @Published var purchaseLog: [[String: String]]      // Geri yukleme icin satin alim kaydi

    static let startingCredits = 10
    static let allCaseIds = ["istanbul-001", "london-003", "girne-005", "napoli-004", "paris-002", "manhattan-006"]

    init() {
        self.credits = Self.startingCredits
        self.unlockedCases = Self.allCaseIds
        self.completedCases = [:]
        self.totalCasesSolved = 0
        self.purchasedCases = []
        self.accusationHistory = [:]
        self.purchaseLog = []
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case credits, unlockedCases, completedCases, totalCasesSolved
        case purchasedCases, accusationHistory, purchaseLog
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credits = try container.decode(Int.self, forKey: .credits)
        unlockedCases = try container.decode([String].self, forKey: .unlockedCases)
        completedCases = try container.decode([String: String].self, forKey: .completedCases)
        totalCasesSolved = try container.decode(Int.self, forKey: .totalCasesSolved)
        purchasedCases = try container.decodeIfPresent([String].self, forKey: .purchasedCases) ?? []
        accusationHistory = try container.decodeIfPresent([String: Int].self, forKey: .accusationHistory) ?? [:]
        purchaseLog = try container.decodeIfPresent([[String: String]].self, forKey: .purchaseLog) ?? []

        // Eski kayitlarda eksik kalan yeni vakalari otomatik ekle
        for caseId in Self.allCaseIds {
            if !unlockedCases.contains(caseId) {
                unlockedCases.append(caseId)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credits, forKey: .credits)
        try container.encode(unlockedCases, forKey: .unlockedCases)
        try container.encode(completedCases, forKey: .completedCases)
        try container.encode(totalCasesSolved, forKey: .totalCasesSolved)
        try container.encode(purchasedCases, forKey: .purchasedCases)
        try container.encode(accusationHistory, forKey: .accusationHistory)
        try container.encode(purchaseLog, forKey: .purchaseLog)
    }

    // MARK: - Kredi Islemleri

    func canAfford(_ cost: Int) -> Bool {
        credits >= cost
    }

    func spendCredits(_ amount: Int) -> Bool {
        guard canAfford(amount) else { return false }
        credits -= amount
        return true
    }

    func addCredits(_ amount: Int) {
        credits += amount
        SaveManager.savePlayerProfile(self)
    }

    // MARK: - Premium Vaka Satin Alim

    func hasPurchasedCase(_ caseId: String) -> Bool {
        purchasedCases.contains(caseId)
    }

    func purchasePremiumCase(_ caseId: String) {
        guard !purchasedCases.contains(caseId) else { return }
        purchasedCases.append(caseId)
    }

    // MARK: - Suclama Sayaci

    func accusationCount(for caseId: String) -> Int {
        accusationHistory[caseId] ?? 0
    }

    func recordAccusation(for caseId: String) {
        accusationHistory[caseId] = (accusationHistory[caseId] ?? 0) + 1
    }

    // MARK: - Satin Alim Kaydi (RC geri yukleme icin)

    func recordPurchase(productId: String, credits: Int) {
        purchaseLog.append([
            "productId": productId,
            "credits": "\(credits)",
            "date": ISO8601DateFormatter().string(from: Date())
        ])
    }
}
