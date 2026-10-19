import SwiftData
import SwiftUI

struct ProfileView: View {
    let currentUser: UserAccount

    @Environment(\.modelContext) private var context
    @Environment(AppSession.self) private var session
    @Query private var slots: [DutySlot]
    @Query private var ratings: [RatingRecord]

    @State private var displayName: String = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var message: String?
    @State private var messageIsError = false
    @State private var showLogoutConfirm = false

    private var thisWeek: Int { WeekCalendar.weekKey(for: Date()) }

    private var myDuties: [DutySlot] {
        slots
            .filter { $0.weekKey == thisWeek && $0.userID == currentUser.userID }
            .sorted { $0.weekday < $1.weekday }
    }

    private var received: [RatingRecord] {
        ratings.filter { $0.toUserID == currentUser.userID }
    }

    private var average: Double {
        guard !received.isEmpty else { return 0 }
        return Double(received.map(\.stars).reduce(0, +)) / Double(received.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KitchenTheme.cream.ignoresSafeArea()
                List {
                    Section {
                        HStack(spacing: 14) {
                            Text(String(currentUser.displayName.prefix(1)).uppercased())
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(KitchenTheme.orange, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentUser.displayName)
                                    .font(.title3.bold())
                                Text("@\(currentUser.username)")
                                    .foregroundStyle(.secondary)
                                if currentUser.isAdmin {
                                    Text("Администратор")
                                        .font(.caption.bold())
                                        .foregroundStyle(KitchenTheme.orange)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section("Эта неделя") {
                        if myDuties.isEmpty {
                            Text("День ещё не выбран. Откройте вкладку «Неделя» и запишите блюдо.")
                        } else {
                            ForEach(myDuties, id: \.slotID) { slot in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(WeekCalendar.weekdayNames[slot.weekday - 1])
                                        .font(.headline)
                                    Text(slot.dish.isEmpty ? "Блюдо не указано" : slot.dish)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        LabeledContent("Средняя оценка") {
                            Text(received.isEmpty ? "пока нет" : String(format: "%.1f ★", average))
                        }
                        LabeledContent("Всего оценок") {
                            Text("\(received.count)")
                        }
                    }

                    Section("Имя в кабинете") {
                        TextField("Имя", text: $displayName)
                        Button("Сохранить имя") { saveName() }
                    }

                    Section("Сменить пароль") {
                        SecureField("Текущий пароль", text: $currentPassword)
                        SecureField("Новый пароль (от 6 символов)", text: $newPassword)
                        Button("Обновить пароль") { savePassword() }
                    }

                    if let message {
                        Section {
                            Text(message)
                                .foregroundStyle(messageIsError ? .red : .green)
                        }
                    }

                    Section {
                        Button("Выйти из кабинета", role: .destructive) {
                            showLogoutConfirm = true
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Кабинет")
            .onAppear {
                displayName = currentUser.displayName
            }
            .confirmationDialog("Выйти?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Выйти", role: .destructive) {
                    session.signOut()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Данные останутся на этом устройстве. Войти можно снова по логину и паролю.")
            }
        }
    }

    private func saveName() {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            show("Введите имя.", error: true)
            return
        }
        currentUser.displayName = name
        do {
            try context.save()
            show("Имя обновлено.", error: false)
        } catch {
            show("Не удалось сохранить имя.", error: true)
        }
    }

    private func savePassword() {
        do {
            try AuthService.changePassword(
                user: currentUser,
                current: currentPassword,
                newPassword: newPassword
            )
            try context.save()
            currentPassword = ""
            newPassword = ""
            show("Пароль обновлён.", error: false)
        } catch {
            show(error.localizedDescription, error: true)
        }
    }

    private func show(_ text: String, error: Bool) {
        message = text
        messageIsError = error
    }
}
