import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: FOLIOAppState
    @StateObject private var feedListVM = FeedListViewModel()
    @StateObject private var articleListVM = ArticleListViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .environmentObject(appState)
                .environmentObject(feedListVM)
        } content: {
            ArticleListView()
                .environmentObject(appState)
                .environmentObject(articleListVM)
        } detail: {
            ReaderView()
                .environmentObject(appState)
                .environmentObject(articleListVM)
        }
        .sheet(isPresented: $appState.showAddFeedSheet) {
            AddFeedSheet()
                .environmentObject(appState)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
