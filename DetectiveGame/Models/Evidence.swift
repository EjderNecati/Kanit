import Foundation

struct Evidence: Codable, Identifiable {
    let id: String                      // "otopsi_raporu"
    let title: String                   // "Otopsi Raporu"
    let description: String             // Detayli aciklama
    let image: String?                  // Delil gorseli (opsiyonel)
    let linkedCharacterId: String?      // Bagli oldugu supheli
    let eliminates: [String]?           // Bu delil hangi suphelileri eler
}
