import Foundation
import Combine

struct APIClient {
    private let baseURL = "http://127.0.0.1:5005/api"
    
    // Send a chat message to the API
    func sendChatMessage(message: String, useScreenContext: Bool = false) -> AnyPublisher<ChatResponse, Error> {
        var parameters: [String: Any] = ["message": message, "use_screen_context": useScreenContext]
        
        if useScreenContext {
            // Get context from the ContextCapture singleton, which now keeps only the last 5 captures in memory
            let contextText = ContextCapture.shared.getContext()
            parameters["context"] = contextText
        }
        
        return makeRequest(endpoint: "/chat", parameters: parameters)
    }
    
    // Clear chat history
    func clearHistory() -> AnyPublisher<String, Error> {
        return makeRequest(endpoint: "/clear_history", parameters: [:])
            .map { _ in "Success" }
            .eraseToAnyPublisher()
    }
    
    // Set academic mode
    func setAcademicMode(isAcademic: Bool) -> AnyPublisher<String, Error> {
        let parameters = ["academic_mode": isAcademic]
        return makeRequest(endpoint: "/set_mode", parameters: parameters)
            .map { _ in "Success" }
            .eraseToAnyPublisher()
    }
    
    // Set selected windows for capture
    func setSelectedWindows(windowIds: [Int]) -> AnyPublisher<String, Error> {
        let parameters = ["window_ids": windowIds]
        return makeRequest(endpoint: "/set_windows", parameters: parameters)
            .map { _ in "Success" }
            .eraseToAnyPublisher()
    }
    
    // Set selected files for context
    func setSelectedFiles(filePaths: [String]) -> AnyPublisher<String, Error> {
        let parameters = ["file_paths": filePaths]
        return makeRequest(endpoint: "/set_files", parameters: parameters)
            .map { _ in "Success" }
            .eraseToAnyPublisher()
    }
    
    // Enable/disable background capture
    func toggleBackgroundCapture(enable: Bool) -> AnyPublisher<String, Error> {
        let parameters = ["enable": enable]
        return makeRequest(endpoint: "/toggle_background_capture", parameters: parameters)
            .map { _ in "Success" }
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