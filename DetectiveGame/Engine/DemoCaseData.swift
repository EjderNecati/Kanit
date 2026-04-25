import Foundation

/// JSON yuklenemezse fallback olarak kullanilacak demo vaka verisi
struct DemoCaseData {
    static var demoCase: Case {
        let jsonString = demoCaseJSON
        guard let data = jsonString.data(using: .utf8),
              let caseData = try? JSONDecoder().decode(Case.self, from: data) else {
            // En son fallback: minimal vaka
            return Case(
                id: "istanbul-001",
                title: "Karanlik Sular",
                subtitle: "Istanbul, 2024",
                city: "Istanbul",
                description: "Demo vaka yuklenemedi.",
                coverImage: "bogaz_gece",
                difficulty: 3,
                isPremium: false,
                evidence: [],
                scenes: [
                    GameScene(
                        id: "scene_001",
                        type: .narration,
                        background: "bogaz_gece",
                        characterId: nil,
                        text: "Demo vaka yuklenemedi. Lutfen case.json dosyasini kontrol edin.",
                        choices: [],
                        addEvidence: nil,
                        addCharacterNote: nil,
                        requiresEvidence: nil,
                        creditCost: nil
                    )
                ],
                characters: [],
                endings: [],
                hqLocations: nil,
                phoneData: nil,
                cameraData: nil,
                labAnalyses: nil,
                contradictions: nil,
                flashbackTriggers: nil,
                newspaperArticles: nil,
                suspectNetwork: nil,
                pressEvents: nil,
                timedEvents: nil,
                suspectAvailability: nil,
                achievements: nil,
                evidenceReactions: nil,
                microExpressions: nil,
                coCulprits: nil
            )
        }
        return caseData
    }

    /// Bundle'dan yukle, yoksa embedded JSON kullan
    static func loadDemoCase() -> Case {
        if let loaded = CaseLoader.loadCase(id: "istanbul-001") {
            return loaded
        }
        return demoCase
    }

    // Embedded JSON  bundle'a erisilemezse bu kullanilir
    private static let demoCaseJSON: String = {
        // JSON dosyasindan oku
        if let url = Bundle.main.url(forResource: "case", withExtension: "json", subdirectory: "Cases/demo-case"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        // Minimal fallback
        return """
        {
            "id": "istanbul-001",
            "title": "Karanlik Sular",
            "subtitle": "Istanbul, 2024",
            "city": "Istanbul",
            "description": "Unlu is insani Kenan Arslanli, Bogaz'daki yalisinda olu bulunur.",
            "coverImage": "bogaz_gece",
            "difficulty": 3,
            "isPremium": false,
            "evidence": [],
            "scenes": [],
            "characters": [],
            "endings": []
        }
        """
    }()
}
