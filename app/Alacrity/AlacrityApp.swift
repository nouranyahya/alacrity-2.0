import SwiftUI

@main
struct AlacrityApp: App {
    @StateObject private var settings = AlacritySettings()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SidebarView(settings: settings, chatViewModel: chatViewModel)
                
                // Default content view
                ChatView(viewModel: chatViewModel, settings: settings)
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        }
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appInfo) {
                Button("About Alacrity") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Alacrity",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "A personal AI assistant for macOS"
                            )
                        ]
                    )
                }
            }
        }
    }
}

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
        .frame(minWidth: 150)
    }
} 