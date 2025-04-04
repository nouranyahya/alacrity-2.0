import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiClient = APIClient()
    private var cancellables = Set<AnyCancellable>()
    
    // Send a message
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // Add user message to list
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        // Clear input field
        let userInput = inputText
        inputText = ""
        
        // Show loading state
        isLoading = true
        errorMessage = nil
        
        // Send to API
        apiClient.sendChatMessage(message: userInput, useScreenContext: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("API Error: \(error)")
                }
            }, receiveValue: { [weak self] response in
                // Add AI response to list
                let aiMessage = ChatMessage(content: response.response, isUser: false)
                self?.messages.append(aiMessage)
            })
            .store(in: &cancellables)
    }
    
    // Clear all messages
    func clearChat() {
        messages = []
        apiClient.clearHistory()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error clearing history: \(error)")
                }
            }, receiveValue: { _ in
                print("History cleared successfully")
            })
            .store(in: &cancellables)
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var settings: AlacritySettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(16)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { messages in
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { isLoading in
                    if isLoading {
                        withAnimation {
                            scrollView.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Input area
            HStack {
                TextField("Ask Alacrity something...", text: $viewModel.inputText)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Alacrity")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.clearChat) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 