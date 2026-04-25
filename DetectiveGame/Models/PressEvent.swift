import Foundation

struct PressEvent: Codable, Identifiable {
    let id: String
    let triggerAfterScenes: Int
    let reporterName: String
    let outlet: String
    let question: String
    let options: [PressOption]

    enum CodingKeys: String, CodingKey {
        case id, triggerAfterScenes, reporterName, outlet, question, options
        case triggerDay, triggerHour // legacy; dosya goc etmemisse okunur
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        reporterName = try c.decode(String.self, forKey: .reporterName)
        outlet = try c.decode(String.self, forKey: .outlet)
        question = try c.decode(String.self, forKey: .question)
        options = try c.decode([PressOption].self, forKey: .options)
        if let t = try c.decodeIfPresent(Int.self, forKey: .triggerAfterScenes) {
            triggerAfterScenes = t
        } else {
            // Legacy gun/saat -> sahne sayisi haritalamasi
            let day = (try c.decodeIfPresent(Int.self, forKey: .triggerDay)) ?? 1
            let hour = (try c.decodeIfPresent(Int.self, forKey: .triggerHour)) ?? 0
            triggerAfterScenes = (day - 1) * 7 + hour / 4
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(triggerAfterScenes, forKey: .triggerAfterScenes)
        try c.encode(reporterName, forKey: .reporterName)
        try c.encode(outlet, forKey: .outlet)
        try c.encode(question, forKey: .question)
        try c.encode(options, forKey: .options)
    }
}

struct PressOption: Codable {
    let text: String
    let effect: String          // "managed", "leak", "ignore", "hint", "hostile", "confident"
    let reputationDelta: Int
    let note: String
}
