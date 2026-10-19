import SwiftData
import SwiftUI

@main
struct KitchenDutyApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(for: [UserAccount.self, DutySlot.self, RatingRecord.self])
    }
}
