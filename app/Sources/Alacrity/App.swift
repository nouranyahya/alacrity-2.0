import SwiftUI
import AppKit

// MARK: - App Definition

struct AlacrityApp: App {
    @StateObject private var settings = AlacritySettings()
    @StateObject private var chatViewModel = ChatViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SidebarView(settings: settings, chatViewModel: chatViewModel)
                    .toolbar {
                        ToolbarItem {
                            Button(action: toggleSidebar) {
                                Label("Toggle Sidebar", systemImage: "sidebar.left")
                            }
                        }
                    }
                
                // Default content view
                ChatView(viewModel: chatViewModel, settings: settings)
            }
            .frame(minWidth: 800, minHeight: 600)
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .navigationTitle("Alacrity")
            .onAppear {
                appDelegate.settings = settings
                appDelegate.ensureWindowIsVisible()
                
                // Start context capture when app launches
                ContextCapture.shared.startCapture()
            }
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appInfo) {
                Button("About Alacrity") {
                    let alert = NSAlert()
                    alert.messageText = "Alacrity"
                    alert.informativeText = "A personal AI assistant for macOS\nVersion 1.0"
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var settings: AlacritySettings?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up to run after a slight delay to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.ensureWindowIsVisible()
        }
        
        // Initialize appearance based on saved preference
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        updateAppearance(isDark: isDarkMode)
    }
    
    func ensureWindowIsVisible() {
        // Forcefully bring app to foreground
        NSApp.activate(ignoringOtherApps: true)
        
        // Make sure a window exists and bring it to front
        if NSApp.windows.isEmpty {
            // If no window exists, create one programmatically
            let contentView = ContentView()
            self.window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            if let window = self.window {
                window.center()
                window.title = "Alacrity"
                window.contentView = NSHostingView(rootView: contentView)
                window.makeKeyAndOrderFront(nil)
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
                window.orderFrontRegardless()
                
                // Extra steps to ensure window is visible
                window.level = .floating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    window.level = .normal
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        } else if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.title = "Alacrity"
            
            // Make window visible on all spaces
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
            
            // Extra steps to ensure window is visible
            window.level = .floating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.level = .normal
                NSApp.activate(ignoringOtherApps: true)
            }
            
            self.window = window
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Add handler when app becomes active to ensure window is visible
    func applicationDidBecomeActive(_ notification: Notification) {
        ensureWindowIsVisible()
    }
    
    // Clean up when app terminates
    func applicationWillTerminate(_ notification: Notification) {
        // Stop capturing screen when app closes
        ContextCapture.shared.stopCapture()
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @ObservedObject var settings: AlacritySettings
    @ObservedObject var chatViewModel: ChatViewModel
    @State private var selection: Int? = 0
    
    var body: some View {
        List(selection: $selection) {
            NavigationLink(destination: ChatView(viewModel: chatViewModel, settings: settings), tag: 0, selection: $selection) {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            
            NavigationLink(destination: SettingsView(settings: settings), tag: 1, selection: $selection) {
                Label("Settings", systemImage: "gear")
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 220)
    }
}

// MARK: - Content View (Fallback)

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Alacrity is Running!")
                    .font(.largeTitle)
                    .padding()
                
                Text("If you can see this window, the UI is working correctly.")
                    .padding()
                
                Button("Open Full UI") {
                    // This is a fallback view - the main UI should normally load
                    if let window = NSApp.windows.first {
                        window.close()
                    }
                    
                    let settings = AlacritySettings()
                    let chatViewModel = ChatViewModel()
                    let contentView = NavigationView {
                        SidebarView(settings: settings, chatViewModel: chatViewModel)
                        ChatView(viewModel: chatViewModel, settings: settings)
                    }
                    
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                        styleMask: [.titled, .closable, .miniaturizable, .resizable],
                        backing: .buffered, 
                        defer: false
                    )
                    window.center()
                    window.title = "Alacrity"
                    window.contentView = NSHostingView(rootView: contentView)
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
                .padding()
            }
        }
    }
} 