import Foundation

// Chat message model
struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// Window model for selection
struct WindowInfo: Identifiable, Codable {
    let id: Int
    let title: String
    var isSelected: Bool = false
}

// API response model
struct ChatResponse: Codable {
    let response: String
    let model: String
    let academic_mode: Bool
}

// App settings model
class AlacritySettings: ObservableObject {
    @Published var academicMode: Bool = false {
        didSet {
            UserDefaults.standard.set(academicMode, forKey: "academicMode")
        }
    }
    
    @Published var captureEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(captureEnabled, forKey: "captureEnabled")
        }
    }
    
    @Published var useWholeScreen: Bool = true {
        didSet {
            UserDefaults.standard.set(useWholeScreen, forKey: "useWholeScreen")
        }
    }
    
    @Published var selectedWindowIds: [Int] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(selectedWindowIds) {
                UserDefaults.standard.set(data, forKey: "selectedWindowIds")
            }
        }
    }
    
    @Published var selectedFilePaths: [String] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(selectedFilePaths) {
                UserDefaults.standard.set(data, forKey: "selectedFilePaths")
            }
        }
    }
    
    init() {
        // Load saved settings
        self.academicMode = UserDefaults.standard.bool(forKey: "academicMode")
        self.captureEnabled = UserDefaults.standard.bool(forKey: "captureEnabled")
        self.useWholeScreen = UserDefaults.standard.bool(forKey: "useWholeScreen")
        
        if let data = UserDefaults.standard.data(forKey: "selectedWindowIds"),
           let decodedIds = try? JSONDecoder().decode([Int].self, from: data) {
            self.selectedWindowIds = decodedIds
        }
        
        if let data = UserDefaults.standard.data(forKey: "selectedFilePaths"),
           let decodedPaths = try? JSONDecoder().decode([String].self, from: data) {
            self.selectedFilePaths = decodedPaths
        }
    }
    
    func clearSelections() {
        selectedWindowIds = []
        selectedFilePaths = []
        useWholeScreen = true
    }
} 