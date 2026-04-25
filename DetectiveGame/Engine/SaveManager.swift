import Foundation

class SaveManager {
    private static let gameStateKey = "savedGameState"
    private static let playerProfileKey = "playerProfile"
    private static let fileManager = FileManager.default

    // MARK: - Kayit Dizini

    private static var saveDirectory: URL {
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return fileManager.temporaryDirectory.appendingPathComponent("Saves", isDirectory: true)
        }
        let saveDir = docs.appendingPathComponent("Saves", isDirectory: true)
        if !fileManager.fileExists(atPath: saveDir.path) {
            try? fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true)
        }
        return saveDir
    }

    // MARK: - GameState Kayit/Yukleme

    static func saveGameState(_ state: GameState) {
        do {
            let data = try JSONEncoder().encode(state)
            let url = saveDirectory.appendingPathComponent("\(state.currentCaseId)_save.json")
            try data.write(to: url)
        } catch {
            print("[SaveManager] GameState kayit hatasi: \(error)")
        }
    }

    static func loadGameState(for caseId: String) -> GameState? {
        let url = saveDirectory.appendingPathComponent("\(caseId)_save.json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            print("[SaveManager] GameState yukleme hatasi: \(error)")
            return nil
        }
    }

    static func deleteSave(for caseId: String) {
        let url = saveDirectory.appendingPathComponent("\(caseId)_save.json")
        try? fileManager.removeItem(at: url)
    }

    static func hasSave(for caseId: String) -> Bool {
        let url = saveDirectory.appendingPathComponent("\(caseId)_save.json")
        return fileManager.fileExists(atPath: url.path)
    }

    /// Verilen case ID'leri icinde kayitli oyun olan ilkini dondur
    static func findAnySave(for caseIds: [String]) -> (caseId: String, state: GameState)? {
        for caseId in caseIds {
            if let state = loadGameState(for: caseId) {
                return (caseId, state)
            }
        }
        return nil
    }

    /// Herhangi bir kayitli oyun var mi?
    static func hasAnySave(for caseIds: [String]) -> Bool {
        caseIds.contains { hasSave(for: $0) }
    }

    // MARK: - PlayerProfile Kayit/Yukleme

    static func savePlayerProfile(_ profile: PlayerProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: playerProfileKey)
        } catch {
            print("[SaveManager] PlayerProfile kayit hatasi: \(error)")
        }
    }

    static func loadPlayerProfile() -> PlayerProfile {
        guard let data = UserDefaults.standard.data(forKey: playerProfileKey) else {
            return PlayerProfile()
        }

        do {
            return try JSONDecoder().decode(PlayerProfile.self, from: data)
        } catch {
            print("[SaveManager] PlayerProfile yukleme hatasi: \(error)")
            return PlayerProfile()
        }
    }
}
