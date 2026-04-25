import Foundation
import SwiftUI

// MARK: - Dil Enum

enum AppLanguage: String, Codable, CaseIterable {
    case turkish = "tr"
    case english = "en"

    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Lokalizasyon Yöneticisi

class LocalizationManager: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            CaseLoader.clearCaseCache()
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr"
        self.language = AppLanguage(rawValue: saved) ?? .turkish
    }

    func s(_ key: StringKey) -> String {
        return key.text(for: language)
    }
}

// MARK: - String Anahtarları

enum StringKey {
    // MainMenu
    case gameTitle
    case tagline
    case continueGame
    case newGame
    case store
    case start

    // CaseSelection
    case files
    case selectCase
    case comingSoon
    case locked
    case solved
    case suspectCount(Int)
    case fileLabel
    case openLabel

    // Store
    case currentCredits
    case creditsInfo
    case restorePurchases
    case buy
    case popular
    case purchaseSuccess
    case creditsAdded(Int)
    case error
    case unknownError
    case ok

    // Game UI
    case evidenceLabel
    case suspectsLabel
    case menu
    case newEvidence
    case noEvidence
    case searchScene
    case insufficientTitle
    case insufficientMsg
    case goToStore
    case cancel
    case save
    case saveAndExit
    case gameMenu
    case howToPlay
    case howToPlayContent
    case restartCase
    case restartConfirmTitle
    case restartConfirmMsg
    case yesRestart
    case startOver
    case tutorialSkip
    case tutorialNext
    case tutorialPrev
    case tutorialFinish
    case trainingCaseBadge
    case playAgainConfirmTitle
    case playAgainConfirmMsg
    case yesPlayAgain
    case backToAccusation
    case backToAccusationConfirmTitle
    case backToAccusationConfirmMsg
    case yesGoBack

    // Accusation
    case accusation
    case selectKiller
    case whoAccuse
    case whatEvidence
    case accuse
    case linkedSuspect(String)

    // Ending
    case epilogue
    case playAgain
    case mainMenu
    case collectedEvidence
    case visitedScenes
    case choicesMade
    case failed

    // Stamps
    case classified
    case solvedStamp
    case coldCase

    // Character
    case statement
    case notes
    case ageLabel(Int, String)
    case noteCount(Int)
    case suspectHeader
    case close
    case back
    case startInvestigation
    case premium
    case credit
    case evidenceDetail
    case nCredits(Int)
    case ageWord
    case occupationWord
    case relationToVictim

    // Headquarters
    case headquarters
    case returnToHQ
    case continueInvestigation
    case evidenceBoard
    case nEvidenceCollected(Int)
    case nScenesVisited(Int)
    case partnerHint0
    case partnerHint1
    case partnerHint2
    case partnerHint3
    case notInterrogated
    case investigation
    case makeAccusation
    case nEvidenceReady(Int)
    case needMoreEvidence(Int)
    case hqScenes
    case hqChoices
    case hqLocations
    case visited
    case interrogated(Int)
    case hqNewEvidence
    case interrogate
    case interrogationComplete
    case nothingLeftToAsk
    case eliminatesSuspect(String)
    case connectionsFound(Int)

    // Phone
    case phoneTitle
    case messagesTab
    case callsTab
    case incomingCall
    case outgoingCall
    case missedCall

    // Camera
    case cameraTitle
    case cameraRec
    case keyEvent

    // Lab
    case labTitle
    case labAnalyzing
    case labComplete
    case labSelectAnalysis

    // Contradictions
    case contradictionsTitle
    case catchContradiction
    case contradictionCaught
    case contradictionLocked
    case contradictionsFound(Int)

    // Flashback
    case flashbacksTitle
    case flashbackStart
    case flashbackTriggered
    case flashbackRequires

    // Newspaper
    case newspaperTitle
    case newspaperSource(String)

    // Network
    case networkTitle

    // Tools
    case toolsSection
    case vs

    // Press
    case pressConference

    // Achievement
    case achievementUnlocked

    // Evidence Reaction
    case showEvidence
    case characterReaction

    // Micro Expression
    case catchExpression

    // Player Notes
    case addNote
    case myNotes
    case noNotes

    // Cross Reference
    case connectionFound

    // MARK: - Çeviri

    func text(for lang: AppLanguage) -> String {
        switch self {

        // MainMenu
        case .gameTitle:
            return "KANIT"
        case .tagline:
            return lang == .turkish ? "Gerçek Katili Bul" : "Find the Real Killer"
        case .continueGame:
            return lang == .turkish ? "Devam Et" : "Continue"
        case .newGame:
            return lang == .turkish ? "Yeni Oyun" : "New Game"
        case .store:
            return lang == .turkish ? "Mağaza" : "Store"
        case .start:
            return lang == .turkish ? "BAŞLA" : "START"

        // CaseSelection
        case .files:
            return lang == .turkish ? "Dosyalar" : "Case Files"
        case .selectCase:
            return lang == .turkish ? "Bir vaka seç ve soruşturmaya başla" : "Pick a case and start investigating"
        case .comingSoon:
            return lang == .turkish ? "Yeni vakalar yakında..." : "New cases coming soon..."
        case .locked:
            return lang == .turkish ? "Kilitli" : "Locked"
        case .solved:
            return lang == .turkish ? "Çözüldü" : "Solved"
        case .suspectCount(let count):
            return lang == .turkish ? "\(count) Şüpheli" : "\(count) Suspects"
        case .fileLabel:
            return lang == .turkish ? "Dosya" : "File"
        case .openLabel:
            return lang == .turkish ? "Açık" : "Open"

        // Store
        case .currentCredits:
            return lang == .turkish ? "Mevcut Kredin" : "Your Credits"
        case .creditsInfo:
            return lang == .turkish
                ? "Krediler kilitli seçenekleri açmak ve özel ipuçlarına erişmek için kullanılır."
                : "Credits are used to unlock choices and access special clues."
        case .restorePurchases:
            return lang == .turkish ? "Satın Alımları Geri Yükle" : "Restore Purchases"
        case .buy:
            return lang == .turkish ? "Satın Al" : "Buy"
        case .popular:
            return lang == .turkish ? "POPÜLER" : "POPULAR"
        case .purchaseSuccess:
            return lang == .turkish ? "Satın Alma Başarılı" : "Purchase Successful"
        case .creditsAdded(let amount):
            return lang == .turkish ? "\(amount) kredi hesabınıza eklendi!" : "\(amount) credits added to your account!"
        case .error:
            return lang == .turkish ? "Hata" : "Error"
        case .unknownError:
            return lang == .turkish ? "Bilinmeyen bir hata oluştu." : "An unknown error occurred."
        case .ok:
            return lang == .turkish ? "Tamam" : "OK"

        // Game UI
        case .evidenceLabel:
            return lang == .turkish ? "Deliller" : "Evidence"
        case .suspectsLabel:
            return lang == .turkish ? "Şüpheliler" : "Suspects"
        case .menu:
            return lang == .turkish ? "Menü" : "Menu"
        case .newEvidence:
            return lang == .turkish ? "Yeni Delil Bulundu!" : "New Evidence Found!"
        case .noEvidence:
            return lang == .turkish ? "Henüz delil toplanmadı" : "No evidence collected yet"
        case .searchScene:
            return lang == .turkish ? "Olay yerini ara ve tanıkları sorgula" : "Search the crime scene and interrogate witnesses"
        case .insufficientTitle:
            return lang == .turkish ? "Yetersiz Kredi" : "Insufficient Credits"
        case .insufficientMsg:
            return lang == .turkish
                ? "Bu seçeneği açmak için yeterli krediniz yok. Mağazadan kredi satın alabilirsiniz."
                : "You don't have enough credits to unlock this option. You can buy credits from the store."
        case .goToStore:
            return lang == .turkish ? "Mağazaya Git" : "Go to Store"
        case .cancel:
            return lang == .turkish ? "İptal" : "Cancel"
        case .save:
            return lang == .turkish ? "Kaydet" : "Save"
        case .saveAndExit:
            return lang == .turkish ? "Kaydet ve Çık" : "Save & Exit"
        case .gameMenu:
            return lang == .turkish ? "Oyun Menüsü" : "Game Menu"
        case .howToPlay:
            return lang == .turkish ? "Nasıl Oynanır" : "How to Play"
        case .howToPlayContent:
            if lang == .turkish {
                return """
                AMACIN
                Her vaka, çözülmeyi bekleyen bir cinayet ya da soygun. Görevin: delilleri toplayıp katili 5+ kanıtla ispatlamak.

                DELİLLER
                Sahnelerde yapacağın seçimler seni yeni ipuçlarına götürür. Toplanan her delil alttaki 'Deliller' sekmesinde birikir. Bazıları şüphelileri eler, bazıları onları suça bağlar.

                ŞÜPHELİLER
                'Şüpheliler' sekmesinden herkesin profilini, ifadesini ve bağlı delilleri görebilirsin. Karargahtan şüphelileri tekrar sorgulayabilir, delil gösterip tepkilerini ölçebilirsin. Karakterle konuşmaya geri döndüğünde oyun seni baştan başlatmaz, kaldığın noktadan devam edersin.

                SORGULAMA TAMAMLANDI
                Bir şüpheliye sorulacak her şey sorulduğunda karargahta grileşir ve 'Sorgulama tamamlandı' etiketi alır. Üzerine tıklayabilirsin ama elinde yeni bir delil yoksa söyleyecek yeni bir şeyi olmaz, 'Söyleyecek bir şeyim kalmadı' der. Yeni delil bulduğunda daha önce açılmamış sorular gelebilir, o durumda kilitli görünen şüpheliye dönmek mantıklı olur. Yoksa vakit kaybıdır.

                NOTLAR
                'Notlarım' sekmesinden kendi çıkarımlarını yazabilirsin. Yargılarını kanıtla destekle.

                KREDİLER
                Bazı seçenekler (flashback, ipucu, başa dönme) kredi ister. Krediyi 'Mağaza'dan satın alabilirsin.

                SUÇLAMA
                Deliller birikir, parçalar yerine oturur, gerçek suçluyu görmeye başlarsın. Karargaha dön, 'Suçlama Yap' butonuna bas ve adını koy. Yanlış kişiyi seçersen dava elinden kayar; cevabı öğrenmenin bedeli ya bir kredi ile geri dönmek ya da vakayı kaybedip kapıyı kapatmaktır.

                İPUÇLARI
                • Yazı akarken ekrana dokunursan hemen tamamlanır.
                • Karakterlerin çelişkilerini yakalayıp bastırırsan ifadeleri çözülür.
                • Her vaka birden fazla finale sahip. Seçimlerin hikayeyi şekillendirir.
                """
            } else {
                return """
                OBJECTIVE
                Each case is a murder or heist waiting to be solved. Your task: gather evidence and prove the culprit with 5+ clues.

                EVIDENCE
                The choices you make in scenes lead you to new clues. Every collected piece appears in the 'Evidence' tab. Some eliminate suspects, others tie them to the crime.

                SUSPECTS
                Use the 'Suspects' tab to see profiles, statements, and linked evidence. From HQ you can re-interrogate them and show evidence to gauge reactions. When you return to a suspect, the game picks up where you left off, not from the beginning.

                INTERROGATION COMPLETE
                Once you've asked a suspect everything there is to ask, they turn grey in HQ with an 'Interrogation complete' label. You can still tap them, but unless you bring new evidence they have nothing new to say: 'I have nothing left to say'. When you find new evidence, previously locked questions may open up, and returning to a grey suspect may be worth it. Otherwise, it's wasted time.

                NOTES
                In 'My Notes' you can record your deductions. Back up your judgments with proof.

                CREDITS
                Some options (flashbacks, hints, restart) cost credits. You can purchase credits in the 'Store'.

                ACCUSATION
                The evidence stacks up, the pieces fall into place, and the real culprit comes into view. Head back to HQ, hit 'Make Accusation', and put a name on the crime. Accuse the wrong person and the case slips through your fingers; to learn the truth you either spend a credit to go back, or walk away and let the file close.

                TIPS
                • Tap the screen while text types to finish instantly.
                • Catching and pressing characters' contradictions cracks their stories.
                • Every case has multiple endings. Your choices shape the story.
                """
            }
        case .restartCase:
            return lang == .turkish ? "Başa Dön" : "Restart Case"
        case .restartConfirmTitle:
            return lang == .turkish ? "Başa Dönmek İstediğinden Emin Misin?" : "Restart This Case?"
        case .restartConfirmMsg:
            return lang == .turkish
                ? "Bu vakadaki tüm ilerlemen silinecek. Toplanan deliller, ziyaret edilen yerler, sorgulamalar. Hepsi sıfırlanacak. Bu işlem için 1 kredi kullanılacak ve geri alınamaz."
                : "All progress in this case will be erased. Collected evidence, visited locations, interrogations. All reset. This costs 1 credit and cannot be undone."
        case .yesRestart:
            return lang == .turkish ? "Evet, Başa Dön (1 Kredi)" : "Yes, Restart (1 Credit)"
        case .startOver:
            return lang == .turkish ? "Baştan Başla" : "Start Over"
        case .tutorialSkip:
            return lang == .turkish ? "Atla" : "Skip"
        case .tutorialNext:
            return lang == .turkish ? "Sonraki" : "Next"
        case .tutorialPrev:
            return lang == .turkish ? "Önceki" : "Back"
        case .tutorialFinish:
            return lang == .turkish ? "Başlayalım" : "Let's Go"
        case .trainingCaseBadge:
            return lang == .turkish ? "Eğitim" : "Training"
        case .playAgainConfirmTitle:
            return lang == .turkish ? "Tekrar Oynamak İstiyor Musun?" : "Play Again?"
        case .playAgainConfirmMsg:
            return lang == .turkish
                ? "Bu vaka baştan başlayacak. Toplanan deliller, ziyaretler, sorgulamalar. Hepsi sıfırlanacak. Bu işlem 1 kredi kullanır."
                : "This case will restart. Collected evidence, visits, interrogations. All reset. This costs 1 credit."
        case .yesPlayAgain:
            return lang == .turkish ? "Evet, Tekrar Oyna (1 Kredi)" : "Yes, Play Again (1 Credit)"
        case .backToAccusation:
            return lang == .turkish ? "Suçlama Ekranına Geri Dön" : "Back to Accusation"
        case .backToAccusationConfirmTitle:
            return lang == .turkish ? "Suçlama Ekranına Dön?" : "Return to Accusation?"
        case .backToAccusationConfirmMsg:
            return lang == .turkish
                ? "İlerlemen olduğu gibi korunacak. Aynı deliller, aynı notlar. Farklı bir şüpheli seçip yeni bir suçlama yapabilirsin. Bu işlem 2 kredi kullanır."
                : "Your progress stays intact. Same evidence, same notes. You can pick a different suspect and try a new accusation. This costs 2 credits."
        case .yesGoBack:
            return lang == .turkish ? "Evet, Geri Dön (2 Kredi)" : "Yes, Go Back (2 Credits)"

        // Accusation
        case .accusation:
            return lang == .turkish ? "SUÇLAMA" : "ACCUSATION"
        case .selectKiller:
            return lang == .turkish ? "Katili seç ve kanıtlarını sun" : "Select the killer and present your evidence"
        case .whoAccuse:
            return lang == .turkish ? "Kimi suçluyorsun?" : "Who do you accuse?"
        case .whatEvidence:
            return lang == .turkish ? "Hangi delilleri sunuyorsun?" : "What evidence are you presenting?"
        case .accuse:
            return lang == .turkish ? "SUÇLA" : "ACCUSE"
        case .linkedSuspect(let name):
            return lang == .turkish ? "Bağlı şüpheli: \(name)" : "Linked suspect: \(name)"

        // Ending
        case .epilogue:
            return lang == .turkish ? "Epilog" : "Epilogue"
        case .playAgain:
            return lang == .turkish ? "Tekrar Oyna" : "Play Again"
        case .mainMenu:
            return lang == .turkish ? "Ana Menü" : "Main Menu"
        case .collectedEvidence:
            return lang == .turkish ? "Toplanan Delil" : "Collected Evidence"
        case .visitedScenes:
            return lang == .turkish ? "Ziyaret Edilen Sahne" : "Visited Scenes"
        case .choicesMade:
            return lang == .turkish ? "Yapılan Seçim" : "Choices Made"
        case .failed:
            return lang == .turkish ? "BAŞARISIZ" : "FAILED"

        // Stamps
        case .classified:
            return lang == .turkish ? "GİZLİ" : "CLASSIFIED"
        case .solvedStamp:
            return lang == .turkish ? "ÇÖZÜLDÜ" : "SOLVED"
        case .coldCase:
            return lang == .turkish ? "KAPALI DOSYA" : "COLD CASE"

        // Character
        case .statement:
            return lang == .turkish ? "İfade" : "Statement"
        case .notes:
            return lang == .turkish ? "Notlar" : "Notes"
        case .ageLabel(let age, let occupation):
            return lang == .turkish ? "\(age) yaş - \(occupation)" : "Age \(age) - \(occupation)"
        case .noteCount(let count):
            return lang == .turkish ? "\(count) not" : "\(count) notes"
        case .suspectHeader:
            return lang == .turkish ? "ŞÜPHELİLER" : "SUSPECTS"
        case .close:
            return lang == .turkish ? "Kapat" : "Close"
        case .back:
            return lang == .turkish ? "Geri Dön" : "Go Back"
        case .startInvestigation:
            return lang == .turkish ? "Soruşturmaya Başla" : "Start Investigation"
        case .premium:
            return lang == .turkish ? "Premium" : "Premium"
        case .credit:
            return lang == .turkish ? "Kredi" : "Credit"
        case .evidenceDetail:
            return lang == .turkish
                ? "Bu delil soruşturmanın önemli bir parçası."
                : "This evidence is an important part of the investigation."
        case .nCredits(let n):
            return lang == .turkish ? "\(n) Kredi" : "\(n) Credits"
        case .ageWord:
            return lang == .turkish ? "Yaş" : "Age"
        case .occupationWord:
            return lang == .turkish ? "Meslek" : "Occupation"
        case .relationToVictim:
            return lang == .turkish ? "Kurbanla İlişki" : "Relation to Victim"

        // Headquarters
        case .headquarters:
            return lang == .turkish ? "Karargah" : "Headquarters"
        case .returnToHQ:
            return lang == .turkish ? "Karargaha Dön" : "Return to HQ"
        case .continueInvestigation:
            return lang == .turkish ? "Soruşturmaya Devam Et" : "Continue Investigation"
        case .evidenceBoard:
            return lang == .turkish ? "Delil Tahtası" : "Evidence Board"
        case .nEvidenceCollected(let n):
            return lang == .turkish ? "\(n) Delil Toplandı" : "\(n) Evidence Collected"
        case .nScenesVisited(let n):
            return lang == .turkish ? "\(n) Lokasyon Ziyaret Edildi" : "\(n) Locations Visited"
        case .partnerHint0:
            return lang == .turkish
                ? "Henüz delil toplamadınız, Dedektif. Olay yerine gidin veya şüphelilerle konuşun."
                : "No evidence collected yet, Detective. Visit the crime scene or talk to the suspects."
        case .partnerHint1:
            return lang == .turkish
                ? "Birkaç delil topladın ama daha fazlası lazım. Her şeyi incelemeyi unutma."
                : "You've collected some evidence but need more. Don't forget to examine everything."
        case .partnerHint2:
            return lang == .turkish
                ? "İyi ilerliyorsun. Deliller arasındaki bağlantılara dikkat et."
                : "Good progress. Pay attention to the connections between evidence."
        case .partnerHint3:
            return lang == .turkish
                ? "Yeterli delil var gibi görünüyor. Suçlama yapmaya hazır mısın?"
                : "Looks like we have enough evidence. Are you ready to make an accusation?"
        case .notInterrogated:
            return lang == .turkish ? "Sorgulanmadı" : "Not interrogated"
        case .investigation:
            return lang == .turkish ? "Soruşturma" : "Investigation"
        case .makeAccusation:
            return lang == .turkish ? "Suçlama Yap" : "Make Accusation"
        case .nEvidenceReady(let n):
            return lang == .turkish ? "\(n) delil toplandı" : "\(n) evidence collected"
        case .needMoreEvidence(let n):
            return lang == .turkish
                ? "Suçlama için en az 5 delil gerekli (\(n)/5)"
                : "At least 5 evidence required for accusation (\(n)/5)"
        case .hqScenes:
            return lang == .turkish ? "Sahne" : "Scenes"
        case .hqChoices:
            return lang == .turkish ? "Seçim" : "Choices"
        case .hqLocations:
            return lang == .turkish ? "Soruşturma Lokasyonları" : "Investigation Locations"
        case .visited:
            return lang == .turkish ? "Ziyaret Edildi" : "Visited"
        case .interrogated(_):
            return lang == .turkish ? "Sorgulandı" : "Interrogated"
        case .interrogationComplete:
            return lang == .turkish ? "Sorgulama tamamlandı" : "Interrogation complete"
        case .nothingLeftToAsk:
            return lang == .turkish ? "Söyleyecek bir şeyi kalmadı" : "Nothing left to say"
        case .hqNewEvidence:
            return lang == .turkish ? "Yeni delil!" : "New evidence!"
        case .interrogate:
            return lang == .turkish ? "Sorgula" : "Interrogate"
        case .eliminatesSuspect(let name):
            return lang == .turkish ? "\(name) elendi" : "\(name) eliminated"
        case .connectionsFound(let n):
            return lang == .turkish ? "\(n) bağlantı keşfedildi" : "\(n) connections found"

        // Phone
        case .phoneTitle:
            return lang == .turkish ? "Telefon Kayıtları" : "Phone Records"
        case .messagesTab:
            return lang == .turkish ? "Mesajlar" : "Messages"
        case .callsTab:
            return lang == .turkish ? "Aramalar" : "Calls"
        case .incomingCall:
            return lang == .turkish ? "Gelen" : "Incoming"
        case .outgoingCall:
            return lang == .turkish ? "Giden" : "Outgoing"
        case .missedCall:
            return lang == .turkish ? "Cevapsız" : "Missed"

        // Camera
        case .cameraTitle:
            return lang == .turkish ? "Güvenlik Kamerası" : "Security Camera"
        case .cameraRec:
            return "REC"
        case .keyEvent:
            return lang == .turkish ? "Kritik" : "Key"

        // Lab
        case .labTitle:
            return lang == .turkish ? "Laboratuvar" : "Laboratory"
        case .labAnalyzing:
            return lang == .turkish ? "Analiz ediliyor..." : "Analyzing..."
        case .labComplete:
            return lang == .turkish ? "Analiz Tamamlandı" : "Analysis Complete"
        case .labSelectAnalysis:
            return lang == .turkish ? "Analiz Seç" : "Select Analysis"

        // Contradictions
        case .contradictionsTitle:
            return lang == .turkish ? "Çelişkiler" : "Contradictions"
        case .catchContradiction:
            return lang == .turkish ? "Çelişkiyi Yakala!" : "Catch Contradiction!"
        case .contradictionCaught:
            return lang == .turkish ? "Yakalandı!" : "Caught!"
        case .contradictionLocked:
            return lang == .turkish ? "Daha fazla delil gerekli" : "More evidence needed"
        case .contradictionsFound(let n):
            return lang == .turkish ? "\(n) çelişki yakalandı" : "\(n) contradictions caught"

        // Flashback
        case .flashbacksTitle:
            return lang == .turkish ? "Flashback'ler" : "Flashbacks"
        case .flashbackStart:
            return lang == .turkish ? "Flashback'i Başlat" : "Start Flashback"
        case .flashbackTriggered:
            return lang == .turkish ? "Görüldü" : "Viewed"
        case .flashbackRequires:
            return lang == .turkish ? "Gerekli deliller:" : "Required evidence:"

        // Newspaper
        case .newspaperTitle:
            return lang == .turkish ? "Gazete" : "Newspaper"
        case .newspaperSource(let source):
            return lang == .turkish ? "Kaynak: \(source)" : "Source: \(source)"

        // Network
        case .networkTitle:
            return lang == .turkish ? "Şüpheli Ağı" : "Suspect Network"

        // Tools
        case .toolsSection:
            return lang == .turkish ? "Soruşturma Araçları" : "Investigation Tools"
        case .vs:
            return "VS"

        // Press
        case .pressConference:
            return lang == .turkish ? "BASIN TOPLANTISI" : "PRESS CONFERENCE"

        // Achievement
        case .achievementUnlocked:
            return lang == .turkish ? "BAŞARIM AÇILDI" : "ACHIEVEMENT UNLOCKED"

        // Evidence Reaction
        case .showEvidence:
            return lang == .turkish ? "Delil Göster" : "Show Evidence"
        case .characterReaction:
            return lang == .turkish ? "Tepki" : "Reaction"

        // Micro Expression
        case .catchExpression:
            return lang == .turkish ? "YAKALA!" : "CATCH!"

        // Player Notes
        case .addNote:
            return lang == .turkish ? "Not Ekle" : "Add Note"
        case .myNotes:
            return lang == .turkish ? "Notlarım" : "My Notes"
        case .noNotes:
            return lang == .turkish ? "Henüz not eklenmedi" : "No notes yet"

        // Cross Reference
        case .connectionFound:
            return lang == .turkish ? "BAĞLANTI BULUNDU" : "CONNECTION FOUND"
        }
    }
}
