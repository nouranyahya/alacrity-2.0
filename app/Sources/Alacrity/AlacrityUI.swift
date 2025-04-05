import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

// MARK: - View Models

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
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
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

class SettingsViewModel: ObservableObject {
    @Published var availableWindows: [WindowInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let apiClient = APIClient()
    private var cancellables = Set<AnyCancellable>()
    
    // Load available windows
    func loadWindows() {
        isLoading = true
        
        apiClient.getAvailableWindows()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("API Error: \(error)")
                    }
                },
                receiveValue: { [weak self] windows in
                    self?.availableWindows = windows
                }
            )
            .store(in: &cancellables)
    }
    
    // Set academic mode
    func setAcademicMode(isAcademic: Bool) {
        apiClient.setAcademicMode(isAcademic: isAcademic)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error setting academic mode: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // Set selected windows
    func setSelectedWindows(windowIds: [Int]) {
        apiClient.setSelectedWindows(windowIds: windowIds)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error setting windows: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // Set selected files
    func setSelectedFiles(filePaths: [String]) {
        apiClient.setSelectedFiles(filePaths: filePaths)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error setting files: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // Toggle background capture
    func toggleBackgroundCapture(enable: Bool) {
        apiClient.toggleBackgroundCapture(enable: enable)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error toggling background capture: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Main Views

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var settings: AlacritySettings
    @Environment(\.colorScheme) var colorScheme
    
    // Colors for message bubbles
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
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, userBubbleColor: userBubbleColor, assistantBubbleColor: assistantBubbleColor)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(assistantBubbleColor)
                                    .cornerRadius(16)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .id("loading")
                        }
                    }
                    .padding(.vertical, 8)
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
            
            // Input area - using standard SwiftUI TextField instead of custom wrapper
            HStack {
                // Use the new NSViewControllerRepresentable for text input
                TextInputView(text: $viewModel.inputText, onSubmit: viewModel.sendMessage, colorScheme: colorScheme)
                    .frame(height: 36)
                
                // Send button
                if !viewModel.inputText.isEmpty {
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(userBubbleColor)
                    }
                    .disabled(viewModel.isLoading)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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

struct SettingsView: View {
    @ObservedObject var settings: AlacritySettings
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedFiles: [String] = []
    @State private var isShowingFilePicker = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            Section(header: Text("Appearance").font(.headline)) {
                Toggle("Dark Mode", isOn: $settings.isDarkMode)
                    .onChange(of: settings.isDarkMode) { newValue in
                        updateAppearance(isDark: newValue)
                    }
            }
            .padding(.bottom, 10)
            
            Section(header: Text("AI Behavior").font(.headline)) {
                Toggle("Academic Mode", isOn: $settings.academicMode)
                    .help("When enabled, responses will be more formal and educational")
                    .onChange(of: settings.academicMode) { newValue in
                        viewModel.setAcademicMode(isAcademic: newValue)
                    }
            }
            .padding(.bottom, 10)
            
            Section(header: Text("Context Capture").font(.headline)) {
                Toggle("Enable Screen Capture", isOn: $settings.captureEnabled)
                    .help("When enabled, the screen will be captured to provide context")
                    .onChange(of: settings.captureEnabled) { newValue in
                        viewModel.toggleBackgroundCapture(enable: newValue)
                    }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Capture Options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Capture Entire Screen", isOn: $settings.useWholeScreen)
                        .disabled(!settings.captureEnabled)
                    
                    if !settings.useWholeScreen {
                        Text("Select Window(s) to Capture")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        Button("Refresh Window List") {
                            viewModel.loadWindows()
                        }
                        .padding(.vertical, 4)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                ForEach(viewModel.availableWindows) { window in
                                    Toggle(window.title, isOn: Binding(
                                        get: { settings.selectedWindowIds.contains(window.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                settings.selectedWindowIds.append(window.id)
                                            } else {
                                                settings.selectedWindowIds.removeAll { $0 == window.id }
                                            }
                                            viewModel.setSelectedWindows(windowIds: settings.selectedWindowIds)
                                        }
                                    ))
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(height: min(CGFloat(viewModel.availableWindows.count) * 30, 150))
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Text("Select File(s) in Context")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack {
                            Button("Choose Files") {
                                isShowingFilePicker = true
                            }
                            .padding(.vertical, 4)
                            
                            Button("Clear Files") {
                                settings.selectedFilePaths.removeAll()
                                selectedFiles.removeAll()
                                viewModel.setSelectedFiles(filePaths: [])
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if !settings.selectedFilePaths.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading) {
                                    ForEach(settings.selectedFilePaths, id: \.self) { path in
                                        HStack {
                                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                settings.selectedFilePaths.removeAll { $0 == path }
                                                viewModel.setSelectedFiles(filePaths: settings.selectedFilePaths)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(4)
                            }
                            .frame(height: min(CGFloat(settings.selectedFilePaths.count) * 30, 120))
                            .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .disabled(!settings.captureEnabled)
                .padding(.vertical, 6)
                
                Button("Clear All Context Selections") {
                    settings.clearSelections()
                    viewModel.setSelectedWindows(windowIds: [])
                    viewModel.setSelectedFiles(filePaths: [])
                }
                .disabled(!settings.captureEnabled)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle("Settings")
        .onAppear {
            viewModel.loadWindows()
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            do {
                let fileURLs = try result.get()
                let paths = fileURLs.map { $0.path }
                selectedFiles = paths.map { URL(fileURLWithPath: $0).lastPathComponent }
                settings.selectedFilePaths.append(contentsOf: paths)
                viewModel.setSelectedFiles(filePaths: settings.selectedFilePaths)
            } catch {
                print("File selection failed: \(error)")
            }
        }
    }
}

// MARK: - Helper Views

struct MessageBubble: View {
    let message: ChatMessage
    let userBubbleColor: Color
    let assistantBubbleColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .fixedSize(horizontal: false, vertical: true) // This fixes text wrapping
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isUser ? userBubbleColor : assistantBubbleColor
                    )
                    .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Functions

// Update app appearance
func updateAppearance(isDark: Bool) {
    DispatchQueue.main.async {
        NSApp.appearance = isDark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
    }
}

// MARK: - TextInputView (New Component for Text Input)

struct TextInputView: NSViewControllerRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void
    var colorScheme: ColorScheme
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = TextInputController()
        controller.text = text
        controller.onTextChange = { newText in
            text = newText
        }
        controller.onSubmit = onSubmit
        controller.isDarkMode = colorScheme == .dark
        return controller
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard let controller = nsViewController as? TextInputController else { return }
        if controller.text != text {
            controller.text = text
        }
        controller.isDarkMode = colorScheme == .dark
        controller.updateAppearance()
    }
}

class TextInputController: NSViewController {
    var text: String = ""
    var onTextChange: ((String) -> Void)? = nil
    var onSubmit: (() -> Void)? = nil
    var isDarkMode: Bool = false
    private var textField: NSTextField!
    private var containerView: NSView!
    
    override func loadView() {
        containerView = NSView()
        self.view = containerView
        
        // Create text field
        textField = NSTextField()
        textField.placeholderString = "Ask Alacrity something..."
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.delegate = self
        textField.focusRingType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view
        containerView.addSubview(textField)
        
        // Add constraints
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        ])
        
        // Create a background
        let background = NSBox()
        background.boxType = .custom
        background.cornerRadius = 20
        background.fillColor = isDarkMode ? 
            NSColor(red: 0.21, green: 0.21, blue: 0.24, alpha: 1.0) : 
            NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        background.borderWidth = 0
        background.translatesAutoresizingMaskIntoConstraints = false
        
        // Insert the background behind the text field
        containerView.addSubview(background, positioned: .below, relativeTo: textField)
        
        // Set background constraints
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            background.topAnchor.constraint(equalTo: containerView.topAnchor),
            background.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTextField()
        updateAppearance()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(textField)
    }
    
    func updateTextField() {
        if textField.stringValue != text {
            textField.stringValue = text
        }
    }
    
    func updateAppearance() {
        textField.textColor = isDarkMode ? .white : .black
        
        // Update background color
        if let background = containerView.subviews.first as? NSBox {
            background.fillColor = isDarkMode ? 
                NSColor(red: 0.21, green: 0.21, blue: 0.24, alpha: 1.0) : 
                NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        }
    }
}

extension TextInputController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else { return }
        text = textField.stringValue
        onTextChange?(text)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onSubmit?()
            }
            return true
        }
        return false
    }
} 