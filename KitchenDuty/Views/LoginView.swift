import SwiftData
import SwiftUI

struct LoginView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSession.self) private var session
    @Query(sort: \UserAccount.username) private var users: [UserAccount]

    @State private var mode: Mode = .login
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var errorText: String?
    @State private var isBusy = false

    private enum Mode: String, CaseIterable {
        case login = "Вход"
        case register = "Регистрация"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KitchenTheme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        Picker("Режим", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: mode) { _, _ in
                            errorText = nil
                        }

                        card
                        demoHint
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(KitchenTheme.orange)
            Text("Дежурство на кухне")
                .font(.largeTitle.bold())
                .foregroundStyle(KitchenTheme.brown)
                .multilineTextAlignment(.center)
            Text("Личный кабинет, расписание на неделю и оценки")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(title: "Логин", text: $username, systemImage: "person.fill")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if mode == .register {
                field(title: "Имя", text: $displayName, systemImage: "textformat")
            }

            secureField(title: "Пароль", text: $password)

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: submit) {
                HStack {
                    if isBusy {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(mode == .login ? "Войти" : "Создать кабинет")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy)
        }
        .padding(18)
        .background(KitchenTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var demoHint: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Готовые аккаунты для входа")
                .font(.headline)
            Text("Нажмите карточку — логин и пароль подставятся сами.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(SeedData.demoAccounts, id: \.username) { account in
                Button {
                    mode = .login
                    username = account.username
                    password = account.password
                    errorText = nil
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.displayName)
                                .fontWeight(.semibold)
                                .foregroundStyle(KitchenTheme.brown)
                            Text("\(account.username)  ·  \(account.password)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if account.isAdmin {
                            Text("админ")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KitchenTheme.orange.opacity(0.15), in: Capsule())
                                .foregroundStyle(KitchenTheme.deepOrange)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private func field(title: String, text: Binding<String>, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(KitchenTheme.orange)
                TextField(title, text: text)
            }
            .padding(12)
            .background(KitchenTheme.cream, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func secureField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(KitchenTheme.orange)
                SecureField(title, text: text)
            }
            .padding(12)
            .background(KitchenTheme.cream, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func submit() {
        errorText = nil
        isBusy = true
        defer { isBusy = false }

        do {
            let user: UserAccount
            if mode == .login {
                user = try AuthService.login(username: username, password: password, users: users)
            } else {
                user = try AuthService.register(
                    username: username,
                    displayName: displayName,
                    password: password,
                    users: users,
                    context: context
                )
            }
            session.signIn(userId: user.userID)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
