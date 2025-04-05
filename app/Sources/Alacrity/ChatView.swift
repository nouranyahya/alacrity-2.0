import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiClient = APIClient()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Add an initial welcome message
        let welcomeMessage = ChatMessage(
            content: "Welcome to Alacrity! I'm here to help you with any questions or tasks. Just type your message below.",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
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
        // Reset to just the welcome message
        let welcomeMessage = ChatMessage(
            content: "Welcome to Alacrity! I'm here to help you with any questions or tasks. Just type your message below.",
            isUser: false
        )
        messages = [welcomeMessage]
        
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
    @State private var scrollToBottom = false
    @Environment(\.colorScheme) var colorScheme
    
    // Exact iMessage colors
    private var userBubbleColor: Color {
        Color(red: 0.0, green: 0.48, blue: 1.0)
    }
    
    private var assistantBubbleColor: Color {
        colorScheme == .dark ? Color(red: 0.27, green: 0.27, blue: 0.3) : Color(red: 0.93, green: 0.93, blue: 0.93)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, userBubbleColor: userBubbleColor, assistantBubbleColor: assistantBubbleColor)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                Spacer(minLength: 60)
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(assistantBubbleColor)
                                    .cornerRadius(16)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                .onReceive(viewModel.$messages) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onReceive(viewModel.$isLoading) { isLoading in
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
            
            // Input area - styled like iMessage
            HStack(spacing: 10) {
                TextField("Ask Alacrity something...", text: $viewModel.inputText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? Color(red: 0.21, green: 0.21, blue: 0.24) : Color(red: 0.93, green: 0.93, blue: 0.93))
                    .cornerRadius(18)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(userBubbleColor)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .overlay(
                Divider().opacity(0.3),
                alignment: .top
            )
        }
        .navigationTitle("Alacrity")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: viewModel.clearChat) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let userBubbleColor: Color
    let assistantBubbleColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isUser ? userBubbleColor : assistantBubbleColor
                    )
                    .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                    .clipShape(BubbleShape(isUser: message.isUser))
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let cornerRadius: CGFloat = 4
        var path = Path()
        
        if isUser {
            // User message - rounded with right point
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(270),
                        clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: .degrees(270),
                        endAngle: .degrees(0),
                        clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(90),
                        clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: .degrees(90),
                        endAngle: .degrees(180),
                        clockwise: false)
        } else {
            // Assistant message - rounded with left point
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(90),
                        clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: .degrees(90),
                        endAngle: .degrees(180),
                        clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
            path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(270),
                        clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: .degrees(270),
                        endAngle: .degrees(0),
                        clockwise: true)
        }
        
        return path
    }
} 