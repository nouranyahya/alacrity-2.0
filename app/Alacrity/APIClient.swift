import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

class APIClient {
    private let baseURL = "http://127.0.0.1:5000/api"
    private var cancellables = Set<AnyCancellable>()
    
    // Send a chat message to the API
    func sendChatMessage(message: String, useScreenContext: Bool) -> AnyPublisher<ChatResponse, APIError> {
        guard let url = URL(string: "\(baseURL)/chat") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "message": message,
            "use_screen_context": useScreenContext
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { $0.data }
            .decode(type: ChatResponse.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                if let decodingError = error as? DecodingError {
                    return .decodingFailed(decodingError)
                } else {
                    return .requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Set academic mode
    func setAcademicMode(isAcademic: Bool) -> AnyPublisher<Bool, APIError> {
        guard let url = URL(string: "\(baseURL)/set_mode") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "academic_mode": isAcademic
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { data, response -> Bool in
                return true // Success if we got here
            }
            .mapError { error -> APIError in
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // Set window selection
    func setSelectedWindows(windowIds: [Int]) -> AnyPublisher<Bool, APIError> {
        guard let url = URL(string: "\(baseURL)/set_windows") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "window_ids": windowIds
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { data, response -> Bool in
                return true
            }
            .mapError { error -> APIError in
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // Set selected files
    func setSelectedFiles(filePaths: [String]) -> AnyPublisher<Bool, APIError> {
        guard let url = URL(string: "\(baseURL)/set_files") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "file_paths": filePaths
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { data, response -> Bool in
                return true
            }
            .mapError { error -> APIError in
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // Get available windows
    func getAvailableWindows() -> AnyPublisher<[WindowInfo], APIError> {
        guard let url = URL(string: "\(baseURL)/get_windows") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        struct WindowResponse: Codable {
            let windows: [WindowInfo]
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { APIError.requestFailed($0) }
            .map { $0.data }
            .decode(type: WindowResponse.self, decoder: JSONDecoder())
            .map { $0.windows }
            .mapError { error -> APIError in
                if let decodingError = error as? DecodingError {
                    return .decodingFailed(decodingError)
                } else {
                    return .requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Toggle background capture
    func toggleBackgroundCapture(enable: Bool) -> AnyPublisher<Bool, APIError> {
        guard let url = URL(string: "\(baseURL)/toggle_background_capture") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "enable": enable
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { data, response -> Bool in
                return true
            }
            .mapError { error -> APIError in
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
    
    // Clear conversation history
    func clearHistory() -> AnyPublisher<Bool, APIError> {
        guard let url = URL(string: "\(baseURL)/clear_history") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.requestFailed($0) }
            .map { data, response -> Bool in
                return true
            }
            .mapError { error -> APIError in
                return .requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
} 