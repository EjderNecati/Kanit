import SwiftUI

struct NewspaperView: View {
    let articles: [NewspaperArticle]
    let gameState: GameState
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var expandedArticleId: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Eski kagit arka plan
                Color(red: 0.95, green: 0.92, blue: 0.85)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Gazete basligi
                        newspaperHeader

                        // Makaleler
                        VStack(spacing: 16) {
                            ForEach(articles) { article in
                                let isUnlocked = isArticleUnlocked(article)
                                articleCard(article, isUnlocked: isUnlocked)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(loc.s(.newspaperTitle))
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black.opacity(0.3))
                    }
                }
            }
            .toolbarBackground(Color(red: 0.95, green: 0.92, blue: 0.85).opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var newspaperHeader: some View {
        VStack(spacing: 8) {
            // Ust cizgi
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(height: 2)

            Text(loc.s(.newspaperTitle).uppercased())
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundColor(.black.opacity(0.8))
                .tracking(3)

            // Alt cizgi (cift cizgi)
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 0.5)
            }

            let unlocked = articles.filter { isArticleUnlocked($0) }.count
            Text("\(unlocked)/\(articles.count)")
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.4))
                .italic()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Article Card

    private func articleCard(_ article: NewspaperArticle, isUnlocked: Bool) -> some View {
        let isExpanded = expandedArticleId == article.id

        return Button(action: {
            guard isUnlocked else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedArticleId = isExpanded ? nil : article.id
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                if isUnlocked {
                    unlockedArticle(article, isExpanded: isExpanded)
                } else {
                    lockedArticle(article)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isUnlocked ? Color.white.opacity(0.7) : Color.black.opacity(0.05))
                    .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0.02), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    // MARK: - Unlocked Article

    private func unlockedArticle(_ article: NewspaperArticle, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Headline
            Text(article.headline)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.black.opacity(0.85))
                .lineSpacing(2)

            // Subheadline
            Text(article.subheadline)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(.black.opacity(0.55))
                .italic()

            // Source
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 12, height: 1)
                Text(loc.s(.newspaperSource(article.source)))
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(.black.opacity(0.4))
                    .tracking(0.5)
            }

            // Body (expanded)
            if isExpanded {
                Divider()
                    .background(Color.black.opacity(0.15))

                Text(article.body)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Locked Article

    private func lockedArticle(_ article: NewspaperArticle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.2))

                // Blurred placeholder lines
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 10)
                        .frame(width: 160)
                }
            }

            if let requires = article.requires, !requires.isEmpty {
                let found = requires.filter { gameState.collectedEvidence.contains($0) }.count
                Text("\(found)/\(requires.count)")
                    .font(.system(size: 10, design: .serif))
                    .foregroundColor(.black.opacity(0.2))
            }
        }
    }

    // MARK: - Helpers

    private func isArticleUnlocked(_ article: NewspaperArticle) -> Bool {
        guard let requires = article.requires, !requires.isEmpty else {
            return true // No requirements = always unlocked
        }
        return requires.allSatisfy { gameState.collectedEvidence.contains($0) }
    }
}
