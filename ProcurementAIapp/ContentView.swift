import SwiftUI

struct ContentView: View {
    @StateObject private var store = NoticeStore()

    var body: some View {
        TabView {
            NoticeTypeSelector(store: store)
                .tabItem { Label("New Notice", systemImage: "plus.circle") }

            RepositoryView(store: store)
                .tabItem { Label("Repository", systemImage: "tray.full") }
        }
    }
}
#Preview {
    ContentView()
}
