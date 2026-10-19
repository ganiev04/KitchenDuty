import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSession.self) private var session
    @Query(sort: \UserAccount.username) private var users: [UserAccount]
    @State private var isReady = false

    var body: some View {
        Group {
            if !isReady {
                ZStack {
                    KitchenTheme.cream.ignoresSafeArea()
                    ProgressView("Загрузка…")
                }
            } else if let userId = session.currentUserId,
                      let user = users.first(where: { $0.userID == userId }) {
                MainTabView(currentUser: user)
            } else {
                LoginView()
            }
        }
        .tint(KitchenTheme.orange)
        .onAppear {
            guard !isReady else { return }
            SeedData.ensureInitialData(context: context)
            if let userId = session.currentUserId,
               !users.contains(where: { $0.userID == userId }) {
                let stored = (try? context.fetch(FetchDescriptor<UserAccount>())) ?? []
                if !stored.contains(where: { $0.userID == userId }) {
                    session.signOut()
                }
            }
            isReady = true
        }
    }
}
