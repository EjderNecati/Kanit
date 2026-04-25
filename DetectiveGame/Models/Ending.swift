import Foundation

struct Ending: Codable, Identifiable {
    let id: String                      // "ending_true_justice"
    let title: String                   // "Adalet Yerini Buldu"
    let description: String             // Son aciklamasi
    let suspectAccused: String          // Suclanan supheli ID
    let isCorrect: Bool                 // Dogru cozum mu?
    let requiredEvidence: [String]      // Gereken deliller
    let starsEarned: Int                // 1-3 yildiz
    let epilogueText: String            // Son sonrasi metin
}
