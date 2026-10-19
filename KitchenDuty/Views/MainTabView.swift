import SwiftUI

struct MainTabView: View {
    let currentUser: UserAccount

    var body: some View {
        TabView {
            ScheduleView(currentUser: currentUser)
                .tabItem {
                    Label("Неделя", systemImage: "calendar")
                }

            RatingsView(currentUser: currentUser)
                .tabItem {
                    Label("Оценки", systemImage: "star.fill")
                }

            ProfileView(currentUser: currentUser)
                .tabItem {
                    Label("Кабинет", systemImage: "person.crop.circle")
                }
        }
    }
}
