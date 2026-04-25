import Foundation
import SwiftUI

class StoryEngine: ObservableObject {
    @Published var currentCase: Case?
    @Published var currentScene: GameScene?
    @Published var gameState: GameState?
    @Published var newEvidenceFound: Evidence? = nil
    @Published var showInsufficientCredits: Bool = false
    @Published var pendingPressEvent: PressEvent? = nil
    @Published var caseHasExpired: Bool = false
    @Published var currentAchievement: Achievement? = nil
    /// Karakter tekrar sorgulandiginda sahnenin ustunde gosterilen kisa intro metni.
    /// Her sahne gecisinde otomatik temizlenir, navigateToCharacter tarafindan set edilir.
    @Published var revisitMessage: String? = nil

    private var playerProfile: PlayerProfile
    private var evidenceDismissWork: DispatchWorkItem?

    init(playerProfile: PlayerProfile) {
        self.playerProfile = playerProfile
    }

    // MARK: - Vaka Baslat

    func startCase(_ caseData: Case) {
        guard let firstScene = caseData.scenes.first else { return }

        self.currentCase = caseData
        self.gameState = GameState(caseId: caseData.id, startSceneId: firstScene.id)

        // State temizligi
        self.pendingPressEvent = nil
        self.caseHasExpired = false
        self.newEvidenceFound = nil
        self.revisitMessage = nil

        // Ilk sahneyi dogrudan set et (GameState.init zaten visitedScenes'e ekledi)
        self.currentScene = firstScene

        if let evidenceId = firstScene.addEvidence {
            collectEvidence(evidenceId)
        }
        if let note = firstScene.addCharacterNote, let charId = firstScene.characterId {
            gameState?.addNote(for: charId, note: note)
        }

        // Sonraki sahnelerin gorsellerini onceden yukle
        for choice in firstScene.choices {
            if let nextScene = findScene(id: choice.nextSceneId) {
                CaseLoader.prefetchImage(named: nextScene.background, caseId: caseData.id)
            }
        }
    }

    /// Kayitli oyundan devam et
    func resumeCase(_ caseData: Case, state: GameState) {
        self.currentCase = caseData
        self.gameState = state

        // State temizligi
        self.pendingPressEvent = nil
        self.caseHasExpired = false
        self.newEvidenceFound = nil
        self.revisitMessage = nil

        // Synthetic exhausted sahnesinde kayit olduysa, sahneyi yeniden uret
        let sid = state.currentSceneId
        if sid.hasPrefix(Self.syntheticExhaustedPrefix) {
            let charId = String(sid.dropFirst(Self.syntheticExhaustedPrefix.count))
            // Karakter hala mevcutsa synthetic sahne uret, yoksa ilk sahneye fallback
            if findCharacter(id: charId) != nil {
                presentExhaustedScene(for: charId)
                refreshAllExhaustion()
                return
            } else if let firstScene = caseData.scenes.first {
                state.currentSceneId = firstScene.id
                self.currentScene = firstScene
            }
        } else if let scene = findScene(id: sid) {
            self.currentScene = scene
        } else if let firstScene = caseData.scenes.first {
            // Kaydedilen sahne bulunamazsa ilk sahneye don
            state.currentSceneId = firstScene.id
            self.currentScene = firstScene
        }

        // Eski save'lerde exhaustion yanlis isaretli olabilir; mevcut kurallara gore yeniden hesapla
        refreshAllExhaustion()
    }

    // MARK: - Sahne Navigasyonu

    func makeChoice(_ choice: Choice) {
        guard let gameState = gameState else { return }

        // Kredi kontrolu
        if choice.creditCost > 0 {
            guard playerProfile.spendCredits(choice.creditCost) else {
                showInsufficientCredits = true
                return
            }
        }

        // Secimi kaydet
        gameState.choiceHistory.append(choice.id)

        // Yeni: consumable secenek ise tuketildi olarak isaretle (bir daha gosterilmez)
        if choice.isConsumable {
            gameState.consumedChoices.insert(choice.id)
        }

        // Hedef sahneye git
        guard let nextScene = findScene(id: choice.nextSceneId) else { return }

        // Farkli bir karakterin diyaloguna geciyorsak karakter-aware navigasyon:
        //  - Daha once konusulduysa intro + kaldigi yer
        //  - Tukenmisse "soyleyecek bir sey yok" sahnesi
        //  - Ilk ziyaret ise hub'a dogrudan
        if nextScene.type == .dialogue,
           let targetCharId = nextScene.characterId,
           currentScene?.characterId != targetCharId {
            navigateToCharacter(targetCharId)
            return
        }

        navigateToScene(nextScene)
    }

    // MARK: - Karakter Exhaustion Kontrolu

    /// Karakter artik sorulacak bir sey kalmadi mi?
    /// Kaynak: gameState.exhaustedCharacters set'i.
    /// Bu set, karakterin hub sahnesindeki tum gorunur choice'lar tuketilince doldurulur.
    func isCharacterExhausted(_ characterId: String) -> Bool {
        gameState?.exhaustedCharacters.contains(characterId) ?? false
    }

    /// Karakterin hub sahnesini bul (isCharacterHub == true, yoksa ilk diyalog sahnesi).
    func findCharacterHub(for characterId: String) -> GameScene? {
        guard let currentCase = currentCase else { return nil }
        // Oncelik: explicit hub
        if let explicit = currentCase.scenes.first(where: {
            $0.type == .dialogue && $0.characterId == characterId && $0.isHub
        }) {
            return explicit
        }
        // Fallback: karakterin ilk diyalog sahnesi
        return currentCase.scenes.first {
            $0.type == .dialogue && $0.characterId == characterId
        }
    }

    /// Karaktere konusmaya donus icin hedef sahneyi bul.
    /// Strateji: kullanicinin ziyaret ettigi sahneler arasinda, bu karakterin dialog sahnelerinde
    /// en yeniden en eskiye dogru yuruyerek ilk oynanabilir icerigi olan sahneyi bulur.
    /// Bu sayede user bir branch'in sonunda dead-end'e geldigi zaman hub'a firlatilmaz,
    /// branch'in bir onceki "orta" sahnesine doner (ornek: scene_099 drained -> scene_053'e don).
    ///
    /// Arama sirasi:
    ///   1. visitedScenes reverse order: en son ziyaret edilen karakter sahnelerinden oynanabilir olani
    ///   2. Hub (yukaridaki arama bos cikarsa, baska henuz ziyaret edilmemis hub kollari olabilir)
    ///   3. Hicbiri yoksa nil (karakter tukenmis)
    ///
    /// "Icerik" tanimi: bu karakterin sahnelerine giden choice'lar VEYA non-dialog aksiyon choice'lari.
    /// Baska karaktere giden dialog choice'lari "icerik" sayilmaz (sadece navigasyon).
    func resumeSceneForCharacter(_ characterId: String) -> GameScene? {
        guard let gameState = gameState else { return nil }
        if gameState.exhaustedCharacters.contains(characterId) { return nil }

        // 1) Visited scene'ler arasinda en son ziyaret edilen karakter-dialog sahnelerinde
        //    oynanabilir icerik olani bul.
        for visitedId in gameState.visitedScenes.reversed() {
            guard let scene = findScene(id: visitedId),
                  scene.type == .dialogue,
                  scene.characterId == characterId else { continue }
            if hasOwnContent(in: scene, forCharacter: characterId) {
                return scene
            }
        }

        // 2) Hub oynanabilir mi (kullanici henuz hic ziyaret etmemis hub kollari olabilir)?
        if let hub = findCharacterHub(for: characterId),
           hasOwnContent(in: hub, forCharacter: characterId) {
            return hub
        }

        // 3) Hicbir yerde icerik yok
        return nil
    }

    /// Karakter icin oynanabilir icerik var mi yok mu iki yonlu guncelle.
    /// - Varsa: exhaustedCharacters'tan cikar (yeni delil unlock durumunda gerekli)
    /// - Yoksa ve user zaten karakterle herhangi bir choice aldi: exhaustedCharacters'a ekle
    /// - Yoksa ama user hic choice almadi: set degistirilmez (tukenmek icin once konusmak gerekir)
    /// Kontrol: hub VEYA son kaldigi sahnede filtre sonrasi gorunur choice var mi?
    private func refreshExhaustion(for characterId: String) {
        guard let gameState = gameState else { return }
        let hasContent = hasPlayableContent(for: characterId)
        let wasExhausted = gameState.exhaustedCharacters.contains(characterId)
        // "Konustu" tanimi: karakterin herhangi bir sahnesinde en az bir consumed choice var.
        // (characterLastScene'e dayanmiyoruz cunku hub ilk ziyaret onu set etmiyor ve tek-sahneli
        //  karakterlerde hic set edilmez, bu da exhaustion'u bozardi.)
        let hasEngaged = hasUserEngagedWith(characterId)

        if hasContent {
            if wasExhausted {
                gameState.exhaustedCharacters.remove(characterId)
                #if DEBUG
                print("[Exhaust] \(characterId): icerik geri geldi → tukenmis isareti kaldirildi")
                #endif
            }
        } else if hasEngaged && !wasExhausted {
            gameState.exhaustedCharacters.insert(characterId)
            #if DEBUG
            print("[Exhaust] \(characterId): oynanabilir icerik bitti → tukenmis isaretlendi")
            #endif
        }
    }

    /// Kullanici bu karakterle en az bir choice alip aldi mi?
    /// Karakterin herhangi bir dialog sahnesindeki choice id'si consumedChoices'da ise evet.
    private func hasUserEngagedWith(_ characterId: String) -> Bool {
        guard let gameState = gameState, let currentCase = currentCase else { return false }
        for scene in currentCase.scenes
        where scene.type == .dialogue && scene.characterId == characterId {
            for choice in scene.choices {
                if gameState.consumedChoices.contains(choice.id) {
                    return true
                }
            }
        }
        return false
    }

    /// Karakterin herhangi bir dialog sahnesinde oynanabilir icerik var mi?
    /// Tum ziyaret edilmis karakter sahnelerini + hub'i tarar.
    /// ONEMLI: Sadece bu karaktere ait "ic" icerik sayilir (cross-character jumps haric).
    private func hasPlayableContent(for characterId: String) -> Bool {
        guard let gameState = gameState else { return false }
        // Tum ziyaret edilmis karakter sahneleri
        for visitedId in gameState.visitedScenes {
            guard let scene = findScene(id: visitedId),
                  scene.type == .dialogue,
                  scene.characterId == characterId else { continue }
            if hasOwnContent(in: scene, forCharacter: characterId) {
                return true
            }
        }
        // Hub (henuz ziyaret edilmemis olabilir)
        if let hub = findCharacterHub(for: characterId),
           hasOwnContent(in: hub, forCharacter: characterId) {
            return true
        }
        return false
    }

    /// Sahnedeki gorunur choice'lar arasinda, bu karaktere ait sayilabilecek icerik var mi?
    /// Sayilir: non-dialog hedefler (araştir, mekana git vb.) VE ayni karakterin dialog'una giden choice'lar.
    /// Sayilmaz: farkli karaktere giden dialog choice'lari (bunlar navigasyon, "soru" degil).
    private func hasOwnContent(in scene: GameScene, forCharacter characterId: String) -> Bool {
        let visible = filterVisibleChoices(scene.choices)
        for choice in visible {
            guard let targetScene = findScene(id: choice.nextSceneId) else {
                // Target bulunamadi, guvenli tarafta kal: icerik say
                return true
            }
            if targetScene.type != .dialogue {
                // Non-dialog (investigation vb): icerik
                return true
            }
            if targetScene.characterId == characterId {
                // Ayni karaktere ait dialog sahnesi: icerik
                return true
            }
            // Baska karakter dialog: atla (bu karakterin icerigi sayilmaz)
        }
        return false
    }

    /// Tum karakterlerin exhaustion durumunu yeniden hesapla.
    /// Karakterler arasi bagimlilik oldugu icin birkac pass ile fixed-point yapiyor.
    private func refreshAllExhaustion() {
        guard let currentCase = currentCase else { return }
        let charIds = Set(currentCase.scenes.compactMap { $0.characterId })
        // Max 3 pass: pratikte 1-2 yeterli, pathological durumlarda cap
        for _ in 0..<3 {
            var changed = false
            for id in charIds {
                let before = gameState?.exhaustedCharacters.contains(id) ?? false
                refreshExhaustion(for: id)
                let after = gameState?.exhaustedCharacters.contains(id) ?? false
                if before != after { changed = true }
            }
            if !changed { break }
        }
    }

    /// Bir choice listesini mevcut oyun durumuna gore filtrele.
    /// Filtreler:
    ///  1. Gizli secenek (isHidden) ve gereken delil yok → gizle
    ///  2. Gereken delil var ama oyuncuda yok → gizle
    ///  3. consumedChoices icinde → gizle
    ///  4. requiresLocationVisited saglanmiyorsa → gizle
    ///  5. requiresLocationNotVisited karsilaniyorsa → gizle
    ///  6. Hedef sahne zaten ziyaret edildiyse gizle (dialog/investigation/narration hepsi).
    ///     - HQ lokasyonuna tekrar gitmek istenirse HQ listesinden erisilir.
    ///     - Karakter dialoguna tekrar konusmak istenirse HQ'dan karaktere tiklanir (revisit/exhausted handler).
    ///     - Diger sahneler icin tek sefer yeterlidir (data tasarim sorumlulugu).
    ///  7. Hedef baska bir tukenmis karakterin diyalogu → gizle
    ///  8. Mevcut karakter tukenmisse, baska karaktere giden dialog choice'i → gizle
    func filterVisibleChoices(_ choices: [Choice]) -> [Choice] {
        guard let gameState = gameState else { return [] }

        return choices.filter { choice in
            // 1-2: Delil gereksinimleri
            if choice.isHidden {
                guard let reqId = choice.requiredEvidenceId else { return false }
                if !gameState.hasEvidence(reqId) { return false }
            } else if let reqId = choice.requiredEvidenceId {
                if !gameState.hasEvidence(reqId) { return false }
            }

            // 3: Tuketilmis mi?
            if gameState.consumedChoices.contains(choice.id) { return false }

            // 4: Gereken mekanlar ziyaret edilmis mi?
            if let reqVisited = choice.requiresLocationVisited {
                for loc in reqVisited {
                    if !gameState.visitedScenes.contains(loc) { return false }
                }
            }
            // 5: Yasaklayici "mekan HENUZ ziyaret edilmemis olmali"
            if let reqNotVisited = choice.requiresLocationNotVisited {
                for loc in reqNotVisited {
                    if gameState.visitedScenes.contains(loc) { return false }
                }
            }

            // 6: Hedef sahne zaten ziyaret edildiyse gizle (genel kural).
            //    Her tip sahneyi kapsar (dialogue, investigation, narration, flashback).
            //    Kullanici tekrar erismek isterse HQ'daki lokasyon listesi veya HQ'daki karakter
            //    butonundan giris yapabilir.
            if gameState.visitedScenes.contains(choice.nextSceneId) {
                return false
            }

            // 7: Tukenmis karakterin dialoguna yonelen choice'lari gizle
            //    (Karakterin hub'i henuz ziyaret edilmemis olsa bile; hub visitedScenes'de degilse
            //    kural #6 fire etmez, ama karakter tukenmisse yine de gizlemek istiyoruz.)
            if let nextScene = findScene(id: choice.nextSceneId),
               nextScene.type == .dialogue,
               let targetCharId = nextScene.characterId,
               currentScene?.characterId != targetCharId,
               isCharacterExhausted(targetCharId) {
                return false
            }

            // 8: Su an icinde oldugumuz sahnenin karakteri tukenmis ise,
            //    baska karaktere giden dialog choice'lari gizle.
            //    (Enzo tukenmisse, onun sahnesinde "Tomasso ile konus" cikmasin)
            if let currentChar = currentScene?.characterId,
               isCharacterExhausted(currentChar),
               let nextScene = findScene(id: choice.nextSceneId),
               nextScene.type == .dialogue,
               let targetCharId = nextScene.characterId,
               targetCharId != currentChar {
                return false
            }

            return true
        }
    }

    private func navigateToScene(_ scene: GameScene, fromHQ: Bool = false, revisitBanner: String? = nil) {
        guard let gameState = gameState else { return }

        let alreadyVisited = gameState.visitedScenes.contains(scene.id)
        let wasNewVisit = !alreadyVisited

        // Banner: caller set etmediyse temizlenir (yeni sahne = banner yok)
        revisitMessage = revisitBanner

        // Sahneyi animasyonla degistir
        withAnimation(.easeInOut(duration: 0.4)) {
            self.currentScene = scene
        }

        gameState.currentSceneId = scene.id

        // Ziyaret edilen sahnelere ekle
        if !alreadyVisited {
            gameState.visitedScenes.append(scene.id)
        }

        // Karakter diyalog sahnesindeysek son konumu guncelle (resume icin).
        // AMA: hub'a ilk kez girildiyse lastScene'i set etme. Aksi halde user hub'a
        // uc saniyelik ziyaretten sonra HQ'ya donup tekrar tiklayinca gereksiz revisit
        // banner gorurdu. Hub'a geri donus (characterLastScene zaten dolu ise) guncellenir.
        if scene.type == .dialogue, let charId = scene.characterId {
            let isHub = scene.isHub
            let alreadyHasLast = gameState.characterLastScene[charId] != nil
            if !isHub || alreadyHasLast {
                gameState.characterLastScene[charId] = scene.id
            }
        }

        // Yeni: Sahne yeni ziyaret edildi ve mekan/investigation tipiyse,
        // baska yerlerdeki consumesOnLocationVisit iceren choice'lari otomatik tuket.
        if wasNewVisit, let currentCase = currentCase {
            for s in currentCase.scenes {
                for c in s.choices {
                    if let targets = c.consumesOnLocationVisit,
                       targets.contains(scene.id),
                       !gameState.consumedChoices.contains(c.id) {
                        gameState.consumedChoices.insert(c.id)
                    }
                }
            }
        }

        // Otomatik delil ekleme
        if let evidenceId = scene.addEvidence {
            collectEvidence(evidenceId)
        }

        // Karakter notu ekleme
        if let note = scene.addCharacterNote, let charId = scene.characterId {
            gameState.addNote(for: charId, note: note)
        }

        // Kredi maliyeti (sahne bazli)
        if let cost = scene.creditCost, cost > 0 {
            _ = playerProfile.spendCredits(cost)
        }

        // Basin ve zamanli olaylar: sahne say\u0131s\u0131 tabanl\u0131 trigger
        checkPressEvents()
        checkTimedEvents()

        // Tum karakterlerin tukenme durumunu yeniden hesapla.
        // consumesOnLocationVisit baska karakterlerin choice'larini da tuketmis olabilir,
        // delil toplama da icerik unlock edebilir, bu yuzden tek karakterle sinirlamiyoruz.
        refreshAllExhaustion()

        // Sonraki olasi sahnelerin gorsellerini onceden yukle
        if let caseId = currentCase?.id {
            for choice in scene.choices {
                if let nextScene = findScene(id: choice.nextSceneId) {
                    CaseLoader.prefetchImage(named: nextScene.background, caseId: caseId)
                }
            }
        }
    }

    /// HQ'dan verilen sahne id'sine git.
    /// Karakter diyalog sahnesi ise karakter-aware yonlendirme yapar:
    ///   - Tukenmisse generic "soyleyecek bir sey yok" synthetic sahnesi
    ///   - Daha onceden konusulduysa "tekrar sorguluyorsun" intro + son kaldigi sahne
    ///   - Ilk ziyaret ise hub'a dogrudan
    func navigateFromHQ(to sceneId: String) {
        guard let scene = findScene(id: sceneId) else { return }
        if scene.type == .dialogue, let charId = scene.characterId {
            navigateToCharacter(charId)
            return
        }
        navigateToScene(scene, fromHQ: true)
    }

    /// Karaktere dogrudan navigasyon (HQ'dan veya baska sahneden).
    /// Senaryolar:
    ///   1. Tukenmisse: generic "soyleyecek bir sey yok" sahnesi
    ///   2. Daha once konusulduysa ve icerik varsa: son oynanabilir sahne + "Yine ne var" banner
    ///   3. Ilk ziyaret ve icerik varsa: hub'a dogrudan, banner yok
    ///   4. Ilk ziyaret ve icerik yok (ornegin tum choice'lar evidence-gated): hub'a git (bos da olsa).
    ///      Tukenmis isaretleme yapmayiz cunku henuz konusmadi.
    ///   5. Konusuldu ama icerik kalmadi: tukenmis isaretle, exhausted sahnesi goster
    func navigateToCharacter(_ characterId: String) {
        guard let gameState = gameState else { return }

        // 1) Zaten tukenmis isaretli
        if gameState.exhaustedCharacters.contains(characterId) {
            presentExhaustedScene(for: characterId)
            return
        }

        // Banner icin: user bu karakterin alt sahnesine/kime geri donmus mu? Sadece characterLastScene'e bakalim.
        // (Hub ilk ziyarette characterLastScene set edilmiyor. Bu revisit banner davranisi icin dogru.)
        let shouldShowBanner = gameState.characterLastScene[characterId] != nil
        // Exhausted-belirleme icin: user karakterden en az bir choice aldi mi?
        let hasEngaged = hasUserEngagedWith(characterId)
        let resumeTarget = resumeSceneForCharacter(characterId)

        if let target = resumeTarget {
            if shouldShowBanner {
                // 2) Revisit + banner
                let banner = findCharacter(id: characterId).map { buildRevisitMessage(for: $0) }
                navigateToScene(target, fromHQ: true, revisitBanner: banner)
            } else {
                // 3) Ilk ziyaret (veya hub disi hareket olmadan donus), banner yok
                navigateToScene(target, fromHQ: true)
            }
            return
        }

        // resumeTarget nil → oynanabilir icerik yok
        if hasEngaged {
            // 5) Karakterden en az bir choice alinmis, icerik de bitmis: tukenmis
            gameState.exhaustedCharacters.insert(characterId)
            presentExhaustedScene(for: characterId)
        } else {
            // 4) Hic choice alinmamis ama icerik de yok (tum choice'lar evidence-gated vs.):
            //    Hub'a git bos da olsa. User data text'inden durumu gorur.
            if let hub = findCharacterHub(for: characterId) {
                navigateToScene(hub, fromHQ: true)
            }
        }
    }

    /// Karakterin revisit banner metnini olustur (lokalize)
    private func buildRevisitMessage(for character: Character) -> String {
        let name = character.name
        if currentLang == "en" {
            return "\(name): \"You again. Do you suspect me? If it puts your mind at ease, I can answer anything you ask.\""
        }
        return "\(name): \"Yine ne var. Benden mi şüpheleniyorsunuz yoksa? İçiniz rahatlayacaksa her soruya cevap verebilirim.\""
    }

    // MARK: - Synthetic Sahneler (Revisit Intro & Exhausted)

    private static let syntheticExhaustedPrefix = "_synth_exhausted_"

    private var currentLang: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "tr"
    }

    private func presentExhaustedScene(for characterId: String) {
        guard let character = findCharacter(id: characterId) else { return }
        let scene = makeExhaustedScene(for: character)
        withAnimation(.easeInOut(duration: 0.4)) {
            self.currentScene = scene
        }
        gameState?.currentSceneId = scene.id
        revisitMessage = nil
    }

    private func makeExhaustedScene(for character: Character) -> GameScene {
        let name = character.name
        let text: String
        // Karaktere ozel override varsa onu kullan (ornek: komadaki Ferhat gibi)
        if let custom = character.exhaustedText, !custom.isEmpty {
            text = custom
        } else if currentLang == "en" {
            text = "\(name) turned toward the window and said nothing. Any words you had left dissolved in that silence. Any answers they could have given were buried in it too.\n\nThere was nothing more to ask, and nothing more to hear."
        } else {
            text = "\(name) pencereye döndü, konuşmadı. Söyleyecek söz elinde kalmadı. Onun verebileceği cevap da o sessizliğin altına gömüldü.\n\nSorulacak bir şey kalmamıştı, duyulacak da."
        }

        let bg = findCharacterHub(for: character.id)?.background
            ?? currentScene?.background
            ?? "office-bg"

        return GameScene(
            id: "\(Self.syntheticExhaustedPrefix)\(character.id)",
            type: .dialogue,
            background: bg,
            characterId: character.id,
            text: text,
            choices: [], // Sadece HQ butonu kalir (StoryView UI'dan)
            addEvidence: nil,
            addCharacterNote: nil,
            requiresEvidence: nil,
            creditCost: nil,
            isCharacterHub: nil
        )
    }

    /// Direk sahneye git (suclama, ending vb. icin - tum lifecycle ile)
    func goToScene(_ sceneId: String) {
        guard let scene = findScene(id: sceneId) else { return }
        navigateToScene(scene)
    }

    // MARK: - Basin Olaylari

    /// Global bayrak: false iken basin olaylari hic tetiklenmez. Veri ve UI kodu korunur,
    /// ileride true yapilinca sistem oldugu gibi devreye girer.
    static let pressEventsEnabled: Bool = false

    func checkPressEvents() {
        guard Self.pressEventsEnabled else { return }
        guard let gameState = gameState, let currentCase = currentCase,
              let events = currentCase.pressEvents else { return }

        let scenesVisited = gameState.visitedScenes.count
        for event in events {
            if gameState.answeredPress.contains(event.id) { continue }
            if scenesVisited >= event.triggerAfterScenes {
                pendingPressEvent = event
                return
            }
        }
    }

    func answerPress(eventId: String, choiceIndex: Int) {
        guard let gameState = gameState, let currentCase = currentCase,
              let event = currentCase.pressEvents?.first(where: { $0.id == eventId }) else { return }
        guard !gameState.answeredPress.contains(eventId) else { return }

        gameState.answeredPress.append(eventId)
        let choice = event.options[choiceIndex]
        gameState.changeReputation(event: "press_\(choice.effect)", amount: choice.reputationDelta)
        pendingPressEvent = nil
    }

    // MARK: - Zamanli Olaylar

    func checkTimedEvents() {
        guard let gameState = gameState, let currentCase = currentCase,
              let events = currentCase.timedEvents else { return }

        let scenesVisited = gameState.visitedScenes.count
        for event in events {
            if gameState.triggeredTimedEvents.contains(event.id) { continue }
            guard scenesVisited >= event.triggerAfterScenes else { continue }

            if let evidenceId = event.evidenceId {
                collectEvidence(evidenceId)
            }
            gameState.triggeredTimedEvents.append(event.id)
        }
    }

    // MARK: - Supheli Musaitlik

    func isSuspectAvailable(_ characterId: String) -> (available: Bool, message: String?) {
        // Zaman sistemi kaldirildigi icin musaitlik kontrolu devre disi: herkes her zaman erisilebilir.
        return (true, nil)
    }

    // MARK: - Delil Tepkileri

    func getEvidenceReaction(characterId: String, evidenceId: String) -> EvidenceReaction? {
        guard let reactions = currentCase?.evidenceReactions else { return nil }
        guard let def = reactions.first(where: { $0.characterId == characterId && $0.evidenceId == evidenceId }) else { return nil }
        return EvidenceReaction(reaction: def.reaction, dialogue: def.dialogue)
    }

    // MARK: - Mikro Ifadeler

    func getMicroExpression(for sceneId: String) -> MicroExpressionDef? {
        guard let expressions = currentCase?.microExpressions else { return nil }
        return expressions.first { $0.triggerScene == sceneId }
    }

    // MARK: - Delil Yonetimi

    private func collectEvidence(_ evidenceId: String) {
        guard let gameState = gameState, let currentCase = currentCase else { return }
        guard !gameState.hasEvidence(evidenceId) else { return }

        gameState.addEvidence(evidenceId)
        gameState.changeReputation(event: "evidence_found", amount: 2)

        // Yeni delil eklendi: bazi karakterlerde evidence-gated choice'lar acilmis olabilir.
        // Exhausted isaretli karakterler icerik tekrar oynanabilir hale geldiyse isaret kaldirilir.
        refreshAllExhaustion()

        // Yeni delil bildirimi goster
        if let evidence = currentCase.evidence.first(where: { $0.id == evidenceId }) {
            // Onceki timer'i iptal et (ardisik delil toplama durumu)
            evidenceDismissWork?.cancel()

            withAnimation(.easeOut(duration: 0.3)) {
                newEvidenceFound = evidence
            }
            // 3 saniye sonra bildirimi kapat
            let work = DispatchWorkItem { [weak self] in
                withAnimation {
                    self?.newEvidenceFound = nil
                }
            }
            evidenceDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
        }

        // Achievement kontrol
        checkEvidenceAchievements()
    }

    private func checkEvidenceAchievements() {
        guard let gameState = gameState else { return }
        let count = gameState.collectedEvidence.count

        let achievements: [(Int, String, String, String)] = [
            (1, "İlk İpucu", "İlk delilini topladın!", "magnifyingglass"),
            (5, "Delil Uzmanı", "5 delil topladın!", "doc.text.magnifyingglass"),
            (10, "Usta Dedektif", "10 delil topladın!", "star.fill")
        ]

        for (threshold, title, desc, icon) in achievements {
            if count == threshold {
                let achievement = Achievement(id: "evidence_\(threshold)", title: title, description: desc, icon: icon)
                showAchievement(achievement)
                break
            }
        }
    }

    func showAchievement(_ achievement: Achievement) {
        // Basarim toast'lari devre disi birakildi - hicbir oyunda gosterilmeyecek
        return
    }

    // MARK: - Suclama

    func accuseSuspect(_ suspectIds: [String], withEvidence evidenceIds: [String]) -> Ending? {
        guard let currentCase = currentCase else { return nil }

        // Co-culprit (birden fazla suclu) vakasi kontrolu
        if let coCulprits = currentCase.coCulprits, !coCulprits.isEmpty {
            return resolveCoCulpritEnding(
                suspectIds: suspectIds,
                coCulprits: coCulprits,
                evidenceIds: evidenceIds,
                currentCase: currentCase
            )
        }

        // Tek supheli vakasi (eski mantik)
        guard let suspectId = suspectIds.first else { return nil }
        let matchingEnding = currentCase.endings.first { ending in
            ending.suspectAccused == suspectId
        }

        if let ending = matchingEnding {
            let hasAllEvidence = ending.requiredEvidence.allSatisfy { evidenceIds.contains($0) }
            if ending.isCorrect && hasAllEvidence {
                gameState?.changeReputation(event: "correct_accusation", amount: 15)
                return ending
            }
            if ending.isCorrect && !hasAllEvidence {
                gameState?.changeReputation(event: "correct_accusation", amount: 5)
                return currentCase.endings.first { $0.suspectAccused == suspectId && !$0.isCorrect && $0.starsEarned == 2 }
                    ?? ending
            }
            gameState?.changeReputation(event: "wrong_accusation", amount: -20)
            return ending
        }

        return nil
    }

    /// Birden fazla suclu olan vakalarda ending secimi
    private func resolveCoCulpritEnding(
        suspectIds: [String],
        coCulprits: [String],
        evidenceIds: [String],
        currentCase: Case
    ) -> Ending? {
        let accused = Set(suspectIds)
        let target = Set(coCulprits)

        // Hepsi dogru secilmis mi?
        if accused == target {
            let evCount = evidenceIds.count
            let totalEv = max(currentCase.evidence.count, 1)
            let ratio = Double(evCount) / Double(totalEv)

            let perfect = currentCase.endings.first(where: { $0.isCorrect && $0.starsEarned == 3 })
            let good = currentCase.endings.first(where: { $0.isCorrect && $0.starsEarned == 2 })
            let weak = currentCase.endings.first(where: { !$0.isCorrect && $0.starsEarned == 1
                && target.contains($0.suspectAccused) })

            if ratio >= 0.75, let e = perfect {
                gameState?.changeReputation(event: "correct_accusation", amount: 15)
                return e
            }
            if ratio >= 0.45, let e = good {
                gameState?.changeReputation(event: "correct_accusation", amount: 10)
                return e
            }
            if let e = weak {
                gameState?.changeReputation(event: "correct_accusation", amount: 2)
                return e
            }
            return perfect ?? good
        }

        // Kismi dogru: sadece coCulprit'lerden biri secildi (ve baska kimse)
        let correctlyAccused = accused.intersection(target)
        let wronglyAccused = accused.subtracting(target)

        if !correctlyAccused.isEmpty && wronglyAccused.isEmpty && accused.count < target.count {
            // Sadece biri secildi ama hepsi gerekiyordu
            if let oneOnly = currentCase.endings.first(where: { $0.id.contains("one_only") }) {
                gameState?.changeReputation(event: "wrong_accusation", amount: -10)
                return oneOnly
            }
        }

        // Tamamen yanlis: ilk yanlis secileni kullan
        let wrongId = wronglyAccused.first ?? accused.first ?? ""
        if let ending = currentCase.endings.first(where: { $0.suspectAccused == wrongId }) {
            gameState?.changeReputation(event: "wrong_accusation", amount: -20)
            return ending
        }

        return currentCase.endings.first(where: { !$0.isCorrect && $0.starsEarned == 0 })
    }

    // MARK: - Yardimci Metodlar

    func findScene(id: String) -> GameScene? {
        currentCase?.scenes.first { $0.id == id }
    }

    func findCharacter(id: String) -> Character? {
        currentCase?.characters.first { $0.id == id }
    }

    func findEvidence(id: String) -> Evidence? {
        currentCase?.evidence.first { $0.id == id }
    }

    func getAvailableChoices() -> [Choice] {
        guard let scene = currentScene else { return [] }
        // Tek giris noktasi: filterVisibleChoices tum filtreleri uygular
        return filterVisibleChoices(scene.choices)
    }

    func canAffordChoice(_ choice: Choice) -> Bool {
        choice.creditCost == 0 || playerProfile.canAfford(choice.creditCost)
    }
}
