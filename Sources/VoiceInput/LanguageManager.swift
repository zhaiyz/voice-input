import Cocoa

struct Language: Hashable {
    let code: String
    let displayName: String
    let locale: String
    
    static let english = Language(code: "en", displayName: "English", locale: "en-US")
    static let simplifiedChinese = Language(code: "zh-CN", displayName: "简体中文", locale: "zh-CN")
    static let traditionalChinese = Language(code: "zh-TW", displayName: "繁體中文", locale: "zh-TW")
    static let japanese = Language(code: "ja", displayName: "日本語", locale: "ja-JP")
    static let korean = Language(code: "ko", displayName: "한국어", locale: "ko-KR")
    
    static let all = [english, simplifiedChinese, traditionalChinese, japanese, korean]
}

class LanguageManager {
    static let shared = LanguageManager()
    
    var currentLanguage: Language {
        get {
            let code = UserDefaults.standard.string(forKey: "selected_language") ?? "zh-CN"
            return Language.all.first { $0.code == code } ?? .simplifiedChinese
        }
        set {
            UserDefaults.standard.set(newValue.code, forKey: "selected_language")
        }
    }
    
    var availableLanguages: [Language] {
        return Language.all
    }
}
