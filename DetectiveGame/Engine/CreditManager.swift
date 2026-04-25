import Foundation
import StoreKit

// MARK: - RevenueCat Entegrasyonu
// RevenueCat SDK eklendiginde:
// 1. Xcode > File > Add Package > https://github.com/RevenueCat/purchases-ios
// 2. Asagidaki USE_REVENUECAT flag'ini true yap
// 3. RC_API_KEY'i RevenueCat dashboard'dan al ve buraya yaz

// RevenueCat henuz eklenmedi - StoreKit 2 fallback aktif
// RC SDK eklenince bu dosyayi guncelle:
// import RevenueCat
// let USE_REVENUECAT = true

let RC_API_KEY = "rc_placeholder_key" // RevenueCat'ten alacagin API key

class CreditManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPurchasing: Bool = false

    // Urun ID'leri
    static let creditProducts = [
        "com.ejdernecati.kanit.credits.2",
        "com.ejdernecati.kanit.credits.8",
        "com.ejdernecati.kanit.credits.16"
    ]

    static let creditAmounts: [String: Int] = [
        "com.ejdernecati.kanit.credits.2": 2,
        "com.ejdernecati.kanit.credits.8": 8,
        "com.ejdernecati.kanit.credits.16": 16
    ]

    struct FallbackPack {
        let amount: Int
        let price: String
        let isPopular: Bool
    }

    static let fallbackPacks: [FallbackPack] = [
        FallbackPack(amount: 2, price: "₺70", isPopular: false),
        FallbackPack(amount: 8, price: "₺200", isPopular: true),
        FallbackPack(amount: 16, price: "₺300", isPopular: false)
    ]

    private var playerProfile: PlayerProfile

    init(playerProfile: PlayerProfile) {
        self.playerProfile = playerProfile
    }

    // MARK: - RC Configure (App baslatildiginda cagir)

    static func configureRevenueCat() {
        // RevenueCat SDK eklenince:
        // Purchases.configure(withAPIKey: RC_API_KEY)
        // Purchases.shared.delegate = self
        #if DEBUG
        print("[CreditManager] RevenueCat henuz entegre edilmedi. StoreKit 2 aktif.")
        #endif
    }

    // MARK: - Urunleri Yukle

    func loadProducts() async {
        // TODO: RC eklenince -> Purchases.shared.getOfferings
        do {
            let storeProducts = try await Product.products(for: Self.creditProducts)
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            print("[CreditManager] Urun yukleme hatasi: \(error)")
        }
    }

    // MARK: - Satin Alma

    func purchase(_ product: Product) async -> Bool {
        await MainActor.run { isPurchasing = true }
        defer { Task { @MainActor in isPurchasing = false } }

        // TODO: RC eklenince -> Purchases.shared.purchase(product:)
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                if let amount = Self.creditAmounts[product.id] {
                    await MainActor.run {
                        playerProfile.addCredits(amount)
                        // Satin alim kaydini sakla (geri yukleme icin)
                        playerProfile.recordPurchase(productId: product.id, credits: amount)
                        SaveManager.savePlayerProfile(playerProfile)
                    }
                }
                await transaction.finish()
                return true

            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("[CreditManager] Satin alma hatasi: \(error)")
            return false
        }
    }

    // MARK: - Geri Yukleme

    func restorePurchases() async {
        await MainActor.run { isPurchasing = true }
        defer { Task { @MainActor in isPurchasing = false } }

        // TODO: RC eklenince -> Purchases.shared.restorePurchases
        var total = 0
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let amount = Self.creditAmounts[transaction.productID] {
                    total += amount
                }
            }
        }

        let restored = total
        if restored > 0 {
            await MainActor.run {
                playerProfile.addCredits(restored)
                SaveManager.savePlayerProfile(playerProfile)
            }
        }

        #if DEBUG
        await MainActor.run {
            print("[CreditManager] Geri yukleme: \(restored) kredi")
        }
        #endif
    }

    // MARK: - Premium Vaka Satin Alma

    func purchasePremiumCase(_ caseId: String) -> Bool {
        // Zaten satin alinmis mi?
        if playerProfile.purchasedCases.contains(caseId) {
            return true
        }
        // 2 kredi harca
        guard playerProfile.spendCredits(2) else { return false }
        playerProfile.purchasePremiumCase(caseId)
        SaveManager.savePlayerProfile(playerProfile)
        return true
    }

    // MARK: - Suclama Kredi Kontrolu

    func canAccuse(caseId: String) -> (allowed: Bool, cost: Int) {
        let count = playerProfile.accusationCount(for: caseId)
        if count == 0 {
            // Ilk suclama ucretsiz
            return (true, 0)
        }
        // Sonraki suclamalar 1 kredi
        return (playerProfile.canAfford(1), 1)
    }

    func spendAccusationCredit(caseId: String) -> Bool {
        let count = playerProfile.accusationCount(for: caseId)
        if count == 0 {
            // Ilk suclama ucretsiz - sadece sayaci artir
            playerProfile.recordAccusation(for: caseId)
            return true
        }
        // Sonraki suclamalar 1 kredi
        guard playerProfile.spendCredits(1) else { return false }
        playerProfile.recordAccusation(for: caseId)
        SaveManager.savePlayerProfile(playerProfile)
        return true
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
