import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
        } detail: {
            ArticleListView()
        }
        .sheet(isPresented: $appState.showAddFeedSheet) {
            AddFeedSheet()
                .environmentObject(appState)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
