import SwiftUI

struct MenuBarExtraView: View {
    @EnvironmentObject var appState: FOLIOAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(.accentColor)

                Text("FOLIO")
                    .font(.headline)

                Spacer()

                Text("\(appState.unreadCount) unread")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(appState.feeds.prefix(5)) { feed in
                        HStack {
                            Image(systemName: "newspaper")
                                .font(.caption)

                            Text(feed.displayTitle)
                                .font(.system(size: 12))
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)

            Divider()

            HStack {
                Button("Quit FOLIO") {
                    NSApp.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .frame(width: 280)
        .onAppear {
            appState.updateUnreadCount()
        }
    }
}
