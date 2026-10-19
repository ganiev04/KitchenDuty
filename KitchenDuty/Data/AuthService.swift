import Foundation
import SwiftData

enum AuthError: LocalizedError, Equatable {
    case emptyUsername
    case emptyPassword
    case emptyDisplayName
    case shortUsername
    case shortPassword
    case invalidUsername
    case invalidCredentials
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .emptyUsername:
            return "Введите логин."
        case .emptyPassword:
            return "Введите пароль."
        case .emptyDisplayName:
            return "Введите имя."
        case .shortUsername:
            return "Логин должен быть от 3 символов."
        case .shortPassword:
            return "Пароль должен быть от 6 символов."
        case .invalidUsername:
            return "Логин: латиница, цифры и _ без пробелов."
        case .invalidCredentials:
            return "Неверный логин или пароль."
        case .usernameTaken:
            return "Такой логин уже занят. Выберите другой."
        }
    }
}

enum AuthService {
    static func normalizedUsername(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func login(
        username: String,
        password: String,
        users: [UserAccount]
    ) throws -> UserAccount {
        let login = normalizedUsername(username)
        guard !login.isEmpty else { throw AuthError.emptyUsername }
        guard !password.isEmpty else { throw AuthError.emptyPassword }

        guard let user = users.first(where: { $0.username == login }) else {
            throw AuthError.invalidCredentials
        }
        guard PasswordHasher.matches(password: password, salt: user.salt, hash: user.passwordHash) else {
            throw AuthError.invalidCredentials
        }
        return user
    }

    static func register(
        username: String,
        displayName: String,
        password: String,
        users: [UserAccount],
        context: ModelContext
    ) throws -> UserAccount {
        let login = normalizedUsername(username)
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !login.isEmpty else { throw AuthError.emptyUsername }
        guard login.count >= 3 else { throw AuthError.shortUsername }
        guard login.range(of: "^[a-z0-9_]{3,24}$", options: .regularExpression) != nil else {
            throw AuthError.invalidUsername
        }
        guard !name.isEmpty else { throw AuthError.emptyDisplayName }
        guard !password.isEmpty else { throw AuthError.emptyPassword }
        guard password.count >= 6 else { throw AuthError.shortPassword }
        guard !users.contains(where: { $0.username == login }) else {
            throw AuthError.usernameTaken
        }

        let salt = PasswordHasher.makeSalt()
        let user = UserAccount(
            username: login,
            displayName: name,
            salt: salt,
            passwordHash: PasswordHasher.hash(password: password, salt: salt)
        )
        context.insert(user)
        try context.save()
        return user
    }

    static func changePassword(user: UserAccount, current: String, newPassword: String) throws {
        guard !current.isEmpty, !newPassword.isEmpty else { throw AuthError.emptyPassword }
        guard newPassword.count >= 6 else { throw AuthError.shortPassword }
        guard PasswordHasher.matches(password: current, salt: user.salt, hash: user.passwordHash) else {
            throw AuthError.invalidCredentials
        }
        let salt = PasswordHasher.makeSalt()
        user.salt = salt
        user.passwordHash = PasswordHasher.hash(password: newPassword, salt: salt)
    }
}
