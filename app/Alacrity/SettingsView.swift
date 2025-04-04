import SwiftUI
import Combine
import UniformTypeIdentifiers

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
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("API Error: \(error)")
                }
            }, receiveValue: { [weak self] windows in
                self?.availableWindows = windows
            })
            .store(in: &cancellables)
    }
    
    // Set academic mode
    func setAcademicMode(isAcademic: Bool) {
        apiClient.setAcademicMode(isAcademic: isAcademic)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error setting academic mode: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // Set selected windows
    func setSelectedWindows(windowIds: [Int]) {
        apiClient.setSelectedWindows(windowIds: windowIds)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error setting windows: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // Set selected files
    func setSelectedFiles(filePaths: [String]) {
        apiClient.setSelectedFiles(filePaths: filePaths)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error setting files: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    // Toggle background capture
    func toggleBackgroundCapture(enable: Bool) {
        apiClient.toggleBackgroundCapture(enable: enable)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error toggling capture: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AlacritySettings
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingFilePicker = false
    
    var body: some View {
        Form {
            Section(header: Text("Mode")) {
                Toggle("Academic Focus Mode", isOn: $settings.academicMode)
                    .onChange(of: settings.academicMode) { newValue in
                        viewModel.setAcademicMode(isAcademic: newValue)
                    }
                
                Text(settings.academicMode ? "Using GPT-3.5 for academic assistance" : "Using GPT-4 Mini for general assistance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Screen Capture")) {
                Toggle("Enable Screen Context", isOn: $settings.captureEnabled)
                    .onChange(of: settings.captureEnabled) { newValue in
                        viewModel.toggleBackgroundCapture(enable: newValue)
                    }
                
                if settings.captureEnabled {
                    Toggle("Capture Whole Screen", isOn: $settings.useWholeScreen)
                        .onChange(of: settings.useWholeScreen) { newValue in
                            if newValue {
                                settings.selectedWindowIds = []
                                viewModel.setSelectedWindows(windowIds: [])
                            }
                        }
                }
            }
            
            if settings.captureEnabled && !settings.useWholeScreen {
                Section(header: Text("Selected Windows")) {
                    Button("Refresh Window List") {
                        viewModel.loadWindows()
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if viewModel.availableWindows.isEmpty {
                        Text("No windows found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.availableWindows) { window in
                            HStack {
                                Text(window.title)
                                Spacer()
                                if settings.selectedWindowIds.contains(window.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleWindowSelection(window.id)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("File Context")) {
                Button("Select Files") {
                    showingFilePicker = true
                }
                
                if !settings.selectedFilePaths.isEmpty {
                    ForEach(settings.selectedFilePaths, id: \.self) { path in
                        HStack {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                            Spacer()
                            Button {
                                removeFilePath(path)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    Button("Clear All Files") {
                        settings.selectedFilePaths = []
                        viewModel.setSelectedFiles(filePaths: [])
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(filePaths: $settings.selectedFilePaths)
                .onDisappear {
                    viewModel.setSelectedFiles(filePaths: settings.selectedFilePaths)
                }
        }
        .onAppear {
            viewModel.loadWindows()
        }
    }
    
    private func toggleWindowSelection(_ windowId: Int) {
        if settings.selectedWindowIds.contains(windowId) {
            settings.selectedWindowIds.removeAll { $0 == windowId }
        } else {
            settings.selectedWindowIds.append(windowId)
        }
        
        viewModel.setSelectedWindows(windowIds: settings.selectedWindowIds)
    }
    
    private func removeFilePath(_ path: String) {
        settings.selectedFilePaths.removeAll { $0 == path }
        viewModel.setSelectedFiles(filePaths: settings.selectedFilePaths)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var filePaths: [String]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.content, .text, .plainText, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                
                // Add the file path to our list
                parent.filePaths.append(url.path)
                
                // Stop accessing the security-scoped resource
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}