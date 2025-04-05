import Foundation
import AppKit
import Combine
import Vision

// MARK: - Models

// Chat message model
struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && 
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp
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

// Empty response struct for endpoints that return only status
struct EmptyResponse: Decodable {
    let status: String?
}

// Windows response struct
struct WindowsResponse: Decodable {
    let windows: [WindowInfo]
}

// App settings model
class AlacritySettings: ObservableObject {
    @Published var academicMode: Bool = false {
        didSet {
            UserDefaults.standard.set(academicMode, forKey: "academicMode")
        }
    }
    
    @Published var captureEnabled: Bool = true {
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
    
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            applyColorScheme()
        }
    }
    
    init() {
        // Load saved settings
        self.academicMode = UserDefaults.standard.bool(forKey: "academicMode")
        self.captureEnabled = UserDefaults.standard.bool(forKey: "captureEnabled")
        self.useWholeScreen = UserDefaults.standard.bool(forKey: "useWholeScreen")
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
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
    
    func applyColorScheme() {
        // Use a safer approach to avoid circular dependency
        DispatchQueue.main.async {
            NSApp.windows.forEach { window in
                window.appearance = self.isDarkMode ? 
                    NSAppearance(named: .darkAqua) : 
                    NSAppearance(named: .aqua)
            }
        }
    }
}

// MARK: - API Client

struct APIClient {
    private let baseURL = "http://127.0.0.1:5005/api"
    
    // Send a chat message to the API
    func sendChatMessage(message: String, useScreenContext: Bool = false) -> AnyPublisher<ChatResponse, Error> {
        var parameters: [String: Any] = ["message": message, "use_screen_context": useScreenContext]
        
        if useScreenContext {
            // Get context from the ContextCapture singleton
            let contextText = ContextCapture.shared.getContext()
            parameters["context"] = contextText
        }
        
        return makeRequest(endpoint: "/chat", parameters: parameters)
    }
    
    // Clear chat history
    func clearHistory() -> AnyPublisher<String, Error> {
        return makeRequest(endpoint: "/clear_history", parameters: [:])
            .map { (response: EmptyResponse) -> String in 
                return "Success" 
            }
            .eraseToAnyPublisher()
    }
    
    // Set academic mode
    func setAcademicMode(isAcademic: Bool) -> AnyPublisher<String, Error> {
        let parameters = ["academic_mode": isAcademic]
        return makeRequest(endpoint: "/set_mode", parameters: parameters)
            .map { (response: EmptyResponse) -> String in 
                return "Success" 
            }
            .eraseToAnyPublisher()
    }
    
    // Set selected windows for capture
    func setSelectedWindows(windowIds: [Int]) -> AnyPublisher<String, Error> {
        let parameters = ["window_ids": windowIds]
        return makeRequest(endpoint: "/set_windows", parameters: parameters)
            .map { (response: EmptyResponse) -> String in 
                return "Success" 
            }
            .eraseToAnyPublisher()
    }
    
    // Set selected files for context
    func setSelectedFiles(filePaths: [String]) -> AnyPublisher<String, Error> {
        let parameters = ["file_paths": filePaths]
        return makeRequest(endpoint: "/set_files", parameters: parameters)
            .map { (response: EmptyResponse) -> String in 
                return "Success" 
            }
            .eraseToAnyPublisher()
    }
    
    // Enable/disable background capture
    func toggleBackgroundCapture(enable: Bool) -> AnyPublisher<String, Error> {
        let parameters = ["enable": enable]
        return makeRequest(endpoint: "/toggle_background_capture", parameters: parameters)
            .map { (response: EmptyResponse) -> String in 
                return "Success" 
            }
            .eraseToAnyPublisher()
    }
    
    // Get available windows (for SettingsView)
    func getAvailableWindows() -> AnyPublisher<[WindowInfo], Error> {
        return makeRequest(endpoint: "/get_windows", parameters: [:])
            .map { (response: WindowsResponse) -> [WindowInfo] in 
                return response.windows 
            }
            .eraseToAnyPublisher()
    }
    
    // Generic request method
    private func makeRequest<T: Decodable>(endpoint: String, parameters: [String: Any]) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NSError(domain: "Invalid URL", code: -1, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// MARK: - Context Capture

class ContextCapture {
    static let shared = ContextCapture()
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval = 1.0
    private var lastCaptureTime = Date()
    
    // Keep only the last 5 captures in memory
    private var recentCaptures: [CaptureData] = []
    private let maxRecentCaptures = 5
    
    private init() {}
    
    struct CaptureData {
        let timestamp: Date
        let image: NSImage
        let extractedText: String
    }
    
    func startCapture(interval: TimeInterval = 1.0) {
        guard captureTimer == nil else { return }
        
        captureInterval = interval
        lastCaptureTime = Date()
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            self?.captureScreen()
        }
    }
    
    func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        clearAllCaptures()
    }
    
    private func captureScreen() {
        let settings = AlacritySettings()
        
        guard settings.captureEnabled else {
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastCaptureTime) < captureInterval * 0.8 {
            return
        }
        
        lastCaptureTime = now
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Capture based on selected windows or whole screen
            var screenImage: NSImage?
            
            if settings.useWholeScreen {
                if let mainDisplay = NSScreen.main {
                    if let image = CGWindowListCreateImage(
                        mainDisplay.frame,
                        .optionOnScreenOnly,
                        kCGNullWindowID,
                        .bestResolution
                    ) {
                        screenImage = NSImage(cgImage: image, size: mainDisplay.frame.size)
                    }
                }
            } else if !settings.selectedWindowIds.isEmpty {
                // Get images for selected windows
                let windowIds = settings.selectedWindowIds
                var combinedImage: NSImage?
                
                for windowId in windowIds {
                    if let image = CGWindowListCreateImage(
                        .null,
                        .optionIncludingWindow,
                        CGWindowID(windowId),
                        .bestResolution
                    ) {
                        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                        
                        if combinedImage == nil {
                            combinedImage = nsImage
                        } else {
                            // Use the most recent window
                            combinedImage = nsImage
                        }
                    }
                }
                
                screenImage = combinedImage
            }
            
            guard let capturedImage = screenImage else { return }
            
            // Process the image (resize, extract text)
            let processedImage = self.resizeImage(capturedImage, maxDimension: 1200)
            self.extractTextFromImage(processedImage) { extractedText in
                // Store in memory only
                let captureData = CaptureData(
                    timestamp: now,
                    image: processedImage,
                    extractedText: extractedText
                )
                self.storeCapture(captureData)
            }
        }
    }
    
    private func storeCapture(_ captureData: CaptureData) {
        // Add to recent captures and maintain limit
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.recentCaptures.append(captureData)
            
            // Keep only the most recent captures
            if self.recentCaptures.count > self.maxRecentCaptures {
                self.recentCaptures.removeFirst(self.recentCaptures.count - self.maxRecentCaptures)
            }
        }
    }
    
    func clearAllCaptures() {
        DispatchQueue.main.async { [weak self] in
            self?.recentCaptures.removeAll()
        }
    }
    
    // Get context for API request
    func getContext() -> String {
        var contextText = ""
        
        // Add text from recent captures
        for capture in recentCaptures {
            let timestamp = formatTimestamp(capture.timestamp)
            contextText += "--- Screen Context at \(timestamp) ---\n"
            contextText += capture.extractedText
            contextText += "\n\n"
        }
        
        // Add text from selected files
        let settings = AlacritySettings()
        for filePath in settings.selectedFilePaths {
            if let fileContents = try? String(contentsOfFile: filePath) {
                contextText += "--- File: \(URL(fileURLWithPath: filePath).lastPathComponent) ---\n"
                contextText += fileContents
                contextText += "\n\n"
            }
        }
        
        return contextText
    }
    
    // MARK: - Helper Functions
    
    private func resizeImage(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let originalSize = image.size
        var newSize = originalSize
        
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            if originalSize.width > originalSize.height {
                newSize.height = originalSize.height * (maxDimension / originalSize.width)
                newSize.width = maxDimension
            } else {
                newSize.width = originalSize.width * (maxDimension / originalSize.height)
                newSize.height = maxDimension
            }
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    private func extractTextFromImage(_ image: NSImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else {
                completion("")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedTexts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(recognizedTexts.joined(separator: " "))
        }
        
        // Configure for accurate text detection
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
            completion("")
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Window Listing (Moved from separate file)

// Function to list windows for selection
func listWindows() -> [WindowInfo] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let windowsListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }
    
    var windows: [WindowInfo] = []
    
    for windowInfo in windowsListInfo {
        guard let windowID = windowInfo[kCGWindowNumber as String] as? Int,
              let windowName = windowInfo[kCGWindowName as String] as? String,
              let windowOwnerName = windowInfo[kCGWindowOwnerName as String] as? String,
              !windowName.isEmpty else {
            continue
        }
        
        let displayName = windowName.isEmpty ? windowOwnerName : "\(windowOwnerName): \(windowName)"
        let window = WindowInfo(id: windowID, title: displayName)
        windows.append(window)
    }
    
    return windows.sorted(by: { $0.title < $1.title })
} 