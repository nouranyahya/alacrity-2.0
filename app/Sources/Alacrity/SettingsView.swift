import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit

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
                    print("Error toggling background capture: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AlacritySettings
    @State private var availableWindows: [WindowInfo] = []
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
            }
            .padding(.bottom, 10)
            
            Section(header: Text("Context Capture").font(.headline)) {
                Toggle("Enable Screen Capture", isOn: $settings.captureEnabled)
                    .help("When enabled, the screen will be captured to provide context")
                
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
                            loadAvailableWindows()
                        }
                        .padding(.vertical, 4)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                ForEach(availableWindows) { window in
                                    Toggle(window.title, isOn: Binding(
                                        get: { settings.selectedWindowIds.contains(window.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                settings.selectedWindowIds.append(window.id)
                                            } else {
                                                settings.selectedWindowIds.removeAll { $0 == window.id }
                                            }
                                        }
                                    ))
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(height: min(CGFloat(availableWindows.count) * 30, 150))
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
                }
                .disabled(!settings.captureEnabled)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle("Settings")
        .onAppear {
            loadAvailableWindows()
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
            } catch {
                print("File selection failed: \(error)")
            }
        }
    }
    
    private func loadAvailableWindows() {
        let windowList = listWindows()
        if !windowList.isEmpty {
            availableWindows = windowList
        }
    }
    
    private func listWindows() -> [WindowInfo] {
        var windowList: [WindowInfo] = []
        
        guard let windowInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return windowList
        }
        
        for window in windowInfo {
            guard let windowNumber = window[kCGWindowNumber as String] as? Int,
                  let windowName = window[kCGWindowName as String] as? String,
                  let windowOwner = window[kCGWindowOwnerName as String] as? String,
                  !windowName.isEmpty,
                  windowOwner != "Window Server" else {
                continue
            }
            
            let title = "\(windowOwner): \(windowName)"
            let isSelected = settings.selectedWindowIds.contains(windowNumber)
            windowList.append(WindowInfo(id: windowNumber, title: title, isSelected: isSelected))
        }
        
        return windowList.sorted { $0.title < $1.title }
    }
    
    private func updateAppearance(isDark: Bool) {
        NSApp.appearance = isDark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        
        // Apply to all windows
        NSApp.windows.forEach { window in
            window.appearance = isDark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }
    }
}

// Helper Views for Settings
struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            content
                .padding(.leading, 4)
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct LabelRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}