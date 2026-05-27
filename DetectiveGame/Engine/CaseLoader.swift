import Foundation
import SwiftUI
import ImageIO

class CaseLoader {
    // MARK: - Onbellek
    private static let imageCache = NSCache<NSString, UIImage>()
    private static var cachedCases: [String: [Case]]?

    /// Ekran olcegine gore max piksel genisligi
    private static let screenScale = UIScreen.main.scale
    private static let maxBackgroundWidth: CGFloat = UIScreen.main.bounds.width * screenScale
    private static let maxThumbnailWidth: CGFloat = 150 * screenScale

    /// JSON dosyasindan vaka yukle (dil destekli)
    static func loadCase(id: String, language: AppLanguage = .turkish) -> Case? {
        let subdir = caseSubdirectories[id] ?? id
        let langSuffix = language == .turkish ? "" : "_\(language.rawValue)"

        // 1. Dil-spesifik dosya dene: case_en.json
        if !langSuffix.isEmpty {
            if let url = Bundle.main.url(
                forResource: "case\(langSuffix)",
                withExtension: "json",
                subdirectory: "Cases/\(subdir)"
            ) {
                return decodeCase(from: url)
            }
        }

        // 2. Cases/subdir/case.json dene (varsayilan Turkce)
        if let url = Bundle.main.url(
            forResource: "case",
            withExtension: "json",
            subdirectory: "Cases/\(subdir)"
        ) {
            return decodeCase(from: url)
        }

        // 3. Cases/id/case.json dene (subdir farkli ise)
        if subdir != id, let url = Bundle.main.url(
            forResource: "case",
            withExtension: "json",
            subdirectory: "Cases/\(id)"
        ) {
            return decodeCase(from: url)
        }

        return nil
    }

    /// Mevcut tum vakalarin ID listesini dondur
    static func availableCaseIds() -> [String] {
        return [
            "istanbul-001",
            "london-003",
            "girne-005",
            "napoli-004",
            "paris-002",
            "manhattan-006"
        ]
    }

    /// Subdirectory mapping (bundle klasor adi)
    private static let caseSubdirectories: [String: String] = [
        "istanbul-001": "demo-case",
        "paris-002": "paris-002",
        "london-003": "london-003",
        "napoli-004": "napoli-004",
        "girne-005": "girne-005",
        "manhattan-006": "manhattan-006"
    ]

    /// Tum vakalari yukle (onbellekli, dil destekli)
    static func loadAllCases(language: AppLanguage = .turkish) -> [Case] {
        let langKey = language.rawValue
        if let cached = cachedCases?[langKey] { return cached }
        let cases = availableCaseIds().compactMap { id -> Case? in
            let result = loadCase(id: id, language: language)
            #if DEBUG
            if result == nil {
                print("[CaseLoader] BASARISIZ: \(id) (\(language.rawValue)) yuklenemedi!")
            } else {
                print("[CaseLoader] OK: \(id) yuklendi")
            }
            #endif
            return result
        }
        if cachedCases == nil { cachedCases = [:] }
        cachedCases?[langKey] = cases
        return cases
    }

    /// Cache temizle (dil degistiginde cagirilir)
    static func clearCaseCache() {
        cachedCases = nil
    }

    private static func decodeCase(from url: URL) -> Case? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let caseData = try decoder.decode(Case.self, from: data)
            return caseData
        } catch {
            #if DEBUG
            print("[CaseLoader] JSON decode hatasi: \(url.lastPathComponent) - \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Gorsel Yukleme

    /// Dosya URL'sini bul
    private static func findImageURL(named name: String, caseId: String) -> URL? {
        let subdir = caseSubdirectories[caseId] ?? caseId

        if let url = Bundle.main.url(
            forResource: name, withExtension: "jpg",
            subdirectory: "Cases/\(subdir)/images"
        ) { return url }

        if subdir != caseId, let url = Bundle.main.url(
            forResource: name, withExtension: "jpg",
            subdirectory: "Cases/\(caseId)/images"
        ) { return url }

        return nil
    }

    /// ImageIO ile downsampled gorsel yukle (bellek dostu)
    private static func downsampledImage(from url: URL, maxPixelWidth: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else { return nil }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelWidth
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Bundle'dan UIImage yukle (onbellekli + downsampled)
    static func loadBundleImage(named name: String, caseId: String) -> UIImage? {
        let cacheKey = NSString(string: "\(caseId)/\(name)")

        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let url = findImageURL(named: name, caseId: caseId) else { return nil }

        // Arka plan gorselleri icin ekran genisligine, portreler icin thumbnail boyutuna dusur
        let isPortrait = name.lowercased().contains("portrait")
        let maxWidth = isPortrait ? maxThumbnailWidth : maxBackgroundWidth

        if let image = downsampledImage(from: url, maxPixelWidth: maxWidth) {
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }

        // Fallback: normal yukleme
        if let image = UIImage(contentsOfFile: url.path) {
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }

        return nil
    }

    /// Async versiyon - background thread'de yukle (main thread bloklamaz)
    static func loadBundleImageAsync(named name: String, caseId: String) async -> UIImage? {
        let cacheKey = NSString(string: "\(caseId)/\(name)")
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = loadBundleImage(named: name, caseId: caseId)
                continuation.resume(returning: image)
            }
        }
    }

    /// Gorsel prefetch - sonraki sahne icin onceden yukle
    static func prefetchImage(named name: String, caseId: String) {
        let cacheKey = NSString(string: "\(caseId)/\(name)")
        guard imageCache.object(forKey: cacheKey) == nil else { return }
        DispatchQueue.global(qos: .utility).async {
            _ = loadBundleImage(named: name, caseId: caseId)
        }
    }

    /// SwiftUI Image dondur: once bundle, sonra placeholder
    static func loadImage(named name: String, caseId: String) -> Image {
        if let uiImage = loadBundleImage(named: name, caseId: caseId) {
            return Image(uiImage: uiImage)
        }
        return placeholderImage(for: name)
    }

    /// Gorsel adi bazinda uygun placeholder sec
    private static func placeholderImage(for name: String) -> Image {
        let lowered = name.lowercased()

        if lowered.contains("suspect") || lowered.contains("character") || lowered.contains("portrait") {
            return Image(systemName: "person.circle.fill")
        } else if lowered.contains("evidence") || lowered.contains("delil") {
            return Image(systemName: "doc.text.magnifyingglass")
        } else if lowered.contains("crime") || lowered.contains("olay") {
            return Image(systemName: "exclamationmark.triangle.fill")
        } else if lowered.contains("police") || lowered.contains("karakol") {
            return Image(systemName: "building.columns.fill")
        } else if lowered.contains("night") || lowered.contains("gece") {
            return Image(systemName: "moon.stars.fill")
        } else if lowered.contains("street") || lowered.contains("sokak") {
            return Image(systemName: "road.lanes")
        } else if lowered.contains("hospital") || lowered.contains("hastane") {
            return Image(systemName: "cross.case.fill")
        } else if lowered.contains("office") || lowered.contains("ofis") {
            return Image(systemName: "building.2.fill")
        } else if lowered.contains("restaurant") || lowered.contains("restoran") {
            return Image(systemName: "fork.knife")
        } else if lowered.contains("yali") || lowered.contains("mansion") || lowered.contains("house") {
            return Image(systemName: "house.lodge.fill")
        } else if lowered.contains("boat") || lowered.contains("bogaz") || lowered.contains("sea") {
            return Image(systemName: "water.waves")
        } else if lowered.contains("camera") || lowered.contains("guvenlik") {
            return Image(systemName: "video.fill")
        } else if lowered.contains("phone") || lowered.contains("mesaj") {
            return Image(systemName: "iphone")
        } else if lowered.contains("eczane") || lowered.contains("pharmacy") {
            return Image(systemName: "pill.fill")
        } else {
            return Image(systemName: "photo.fill")
        }
    }
}
