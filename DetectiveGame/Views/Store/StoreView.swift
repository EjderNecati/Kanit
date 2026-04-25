import SwiftUI
import StoreKit

struct StoreView: View {
    @ObservedObject var playerProfile: PlayerProfile
    @StateObject private var creditManager: CreditManager
    @EnvironmentObject var loc: LocalizationManager

    @State private var purchaseError: String? = nil
    @State private var showError = false
    @State private var showSuccess = false
    @State private var purchasedAmount = 0
    @State private var headerGlow = false

    init(playerProfile: PlayerProfile) {
        self.playerProfile = playerProfile
        self._creditManager = StateObject(wrappedValue: CreditManager(playerProfile: playerProfile))
    }

    var body: some View {
        ZStack {
            // Koyu gradient arka plan
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.05, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08),
                    Color(red: 0.06, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - Premium Header
                    VStack(spacing: 12) {
                            // Diamond icon
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.noirSecondary.opacity(0.2), Color.clear],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 50
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 38))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.noirSecondary, Color.noirGold, Color.noirSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.noirSecondary.opacity(0.5), radius: 15)
                            }

                            Text(loc.language == .turkish ? "Kredi Mağazası" : "Credit Store")
                                .font(.system(size: 26, weight: .black, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.noirText, Color.noirSecondary.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .tracking(2)

                            Text(loc.language == .turkish
                                 ? "Dedektif işi kredi ister. Cebinde bulunsun."
                                 : "Detective work takes credits. Stock up.")
                                .font(.system(size: 13, weight: .light, design: .serif))
                                .foregroundColor(.noirMuted.opacity(0.7))
                                .italic()

                            // Kredi gostergesi
                            HStack(spacing: 8) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.noirCredit)
                                Text("\(playerProfile.credits)")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.noirText)
                                    .contentTransition(.numericText())
                                Text(loc.language == .turkish ? "KREDİ" : "CREDITS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.noirMuted)
                                    .tracking(2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.noirPrimary.opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.noirSecondary.opacity(0.4), Color.noirSecondary.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.noirSecondary.opacity(headerGlow ? 0.15 : 0.06), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 360, height: 360)
                            .offset(y: -40)
                            .allowsHitTesting(false)
                    )
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                    // MARK: - Launch indirim rozeti
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.25))
                        Text(loc.language == .turkish ? "LANSMAN FIYATI - %50 İNDİRİM" : "LAUNCH PRICE - 50% OFF")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.25))
                            .tracking(1.5)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.95, green: 0.55, blue: 0.25).opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.95, green: 0.55, blue: 0.25).opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .padding(.bottom, 10)

                    // MARK: - Plan Kartlari
                    VStack(spacing: 14) {
                        ForEach(StorePlan.launchPacks) { plan in
                            PlanCardView(
                                plan: plan,
                                isPurchasing: creditManager.isPurchasing
                            ) {
                                if let product = creditManager.products.first(where: {
                                    CreditManager.creditAmounts[$0.id] == plan.credits
                                }) {
                                    Task {
                                        let success = await creditManager.purchase(product)
                                        if success {
                                            purchasedAmount = plan.credits
                                            showSuccess = true
                                        }
                                    }
                                } else {
                                    Task { await creditManager.loadProducts() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Alt bilgi
                    VStack(spacing: 16) {
                        // Ayirici
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, Color.noirMuted.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 0.5)
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 10))
                                .foregroundColor(.noirMuted.opacity(0.3))
                            Rectangle()
                                .fill(LinearGradient(colors: [Color.noirMuted.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 40)

                        Text(loc.language == .turkish
                             ? "Tek seferlik satın alım. Krediler hesabına anında eklenir."
                             : "One-time purchase. Credits are added to your account instantly.")
                            .font(.system(size: 10))
                            .foregroundColor(.noirMuted.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        Button(action: {
                            Task { await creditManager.restorePurchases() }
                        }) {
                            Text(loc.s(.restorePurchases))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.noirMuted.opacity(0.4))
                                .underline()
                        }
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 50)
                }
            }

            // Loading overlay
            if creditManager.isPurchasing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.noirSecondary)
                        .scaleEffect(1.5)
                    Text(loc.language == .turkish ? "İşleniyor..." : "Processing...")
                        .font(.noirCaption(12))
                        .foregroundColor(.noirMuted)
                }
            }
        }
        .navigationTitle(loc.s(.store))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.06, green: 0.05, blue: 0.12), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await creditManager.loadProducts() }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                headerGlow = true
            }
        }
        .alert(loc.s(.purchaseSuccess), isPresented: $showSuccess) {
            Button(loc.s(.ok)) {}
        } message: {
            Text(loc.s(.creditsAdded(purchasedAmount)))
        }
        .alert(loc.s(.error), isPresented: $showError) {
            Button(loc.s(.ok)) {}
        } message: {
            Text(purchaseError ?? loc.s(.unknownError))
        }
    }
}

// MARK: - Plan Modeli

struct StorePlan: Identifiable {
    let id = UUID()
    let nameTR: String
    let nameEN: String
    let credits: Int
    let price: Int        // Indirimli fiyat (TL)
    let origPrice: Int    // Indirim oncesi (TL)
    let isPopular: Bool
    let perksTR: [String]
    let perksEN: [String]

    var savingsPercent: Int {
        guard origPrice > 0 else { return 0 }
        return Int(round((1.0 - Double(price) / Double(origPrice)) * 100))
    }

    /// Lansman indirimli paketler (%50)
    static let launchPacks: [StorePlan] = [
        StorePlan(
            nameTR: "Dedektif",
            nameEN: "Detective",
            credits: 2,
            price: 70,
            origPrice: 140,
            isPopular: false,
            perksTR: ["1 premium vaka aç"],
            perksEN: ["Unlock 1 premium case"]
        ),
        StorePlan(
            nameTR: "Profesyonel Dedektif",
            nameEN: "Professional Detective",
            credits: 8,
            price: 200,
            origPrice: 400,
            isPopular: true,
            perksTR: ["4 premium vaka aç", "Geri alma + baştan başla"],
            perksEN: ["Unlock 4 premium cases", "Undo + restart"]
        ),
        StorePlan(
            nameTR: "Uzman Dedektif",
            nameEN: "Expert Detective",
            credits: 16,
            price: 300,
            origPrice: 600,
            isPopular: false,
            perksTR: ["8 premium vaka aç", "Geri alma + baştan başla"],
            perksEN: ["Unlock 8 premium cases", "Undo + restart"]
        )
    ]
}

// MARK: - Plan Karti

private struct PlanCardView: View {
    let plan: StorePlan
    let isPurchasing: Bool
    let action: () -> Void
    @EnvironmentObject var loc: LocalizationManager
    @State private var isPressed = false

    private var perks: [String] {
        loc.language == .turkish ? plan.perksTR : plan.perksEN
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Ust: Kredi + Fiyat
                HStack(alignment: .top) {
                    // Sol: Plan adi + Kredi
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.language == .turkish ? plan.nameTR : plan.nameEN)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(plan.isPopular ? .noirSecondary : .noirText)
                            .tracking(0.5)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(plan.credits)")
                                .font(.system(size: 32, weight: .black, design: .serif))
                                .foregroundStyle(
                                    plan.isPopular
                                        ? LinearGradient(colors: [Color.noirSecondary, Color.noirGold], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.noirText, Color.noirText], startPoint: .top, endPoint: .bottom)
                                )
                            Text(loc.language == .turkish ? "kredi" : "credits")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.noirMuted)
                        }
                    }

                    Spacer()

                    // Sag: Fiyat
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(plan.origPrice) TL")
                            .font(.system(size: 12))
                            .foregroundColor(.noirMuted.opacity(0.5))
                            .strikethrough(color: .noirMuted.opacity(0.5))

                        Text("\(plan.price) TL")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.noirSecondary)

                        if plan.savingsPercent > 0 {
                            Text("%\(plan.savingsPercent) \(loc.language == .turkish ? "İndirim" : "off")")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 0.29, green: 0.55, blue: 0.35))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color(red: 0.29, green: 0.55, blue: 0.35).opacity(0.12))
                                )
                        }
                    }
                }

                // Perkler
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(perks, id: \.self) { perk in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(plan.isPopular ? Color.noirSecondary.opacity(0.8) : Color(red: 0.29, green: 0.55, blue: 0.35).opacity(0.75))
                            Text(perk)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.noirMuted.opacity(0.85))
                            Spacer()
                        }
                    }
                }

                // Buton
                HStack(spacing: 6) {
                    if plan.isPopular {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                    }
                    Text(loc.language == .turkish ? "SEÇ" : "SELECT")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .tracking(2)
                }
                .foregroundColor(plan.isPopular ? Color.noirBackground : .noirSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(plan.isPopular
                              ? LinearGradient(colors: [Color.noirSecondary, Color.noirGold], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(plan.isPopular ? Color.clear : Color.noirSecondary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        plan.isPopular
                            ? LinearGradient(
                                colors: [Color.noirSecondary.opacity(0.08), Color.noirPrimary.opacity(0.7), Color.noirSecondary.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.noirPrimary.opacity(0.6), Color.noirPrimary.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                plan.isPopular
                                    ? LinearGradient(colors: [Color.noirSecondary.opacity(0.5), Color.noirSecondary.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.noirMuted.opacity(0.12), Color.noirMuted.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                                lineWidth: plan.isPopular ? 1.5 : 1
                            )
                    )
            )
            .overlay(alignment: .topTrailing) {
                if plan.isPopular {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 7))
                        Text(loc.language == .turkish ? "EN POPÜLER" : "MOST POPULAR")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.noirBackground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.noirSecondary, Color.noirGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .offset(x: -12, y: -8)
                }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.5 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = pressing }
        }, perform: {})
    }
}
