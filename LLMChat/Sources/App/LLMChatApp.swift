import SwiftUI

@main
struct LLMChatApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                    ChatView()
                }
                Tab("Session Lab", systemImage: "slider.horizontal.3") {
                    CustomizationChatView()
                }
            }
        }
    }
}
