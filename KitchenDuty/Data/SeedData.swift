import Foundation
import SwiftData

enum SeedData {
    static let demoAccounts: [(username: String, displayName: String, password: String, isAdmin: Bool)] = [
        ("anna", "Анна", "anna123", false),
        ("ivan", "Иван", "ivan123", false),
        ("maria", "Мария", "maria123", false),
        ("oleg", "Олег", "oleg123", true)
    ]

    static func ensureInitialData(context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<UserAccount>()
            descriptor.fetchLimit = 1
            let existing = try context.fetch(descriptor)
            if existing.isEmpty {
                for account in demoAccounts {
                    let salt = PasswordHasher.makeSalt()
                    let user = UserAccount(
                        username: account.username,
                        displayName: account.displayName,
                        salt: salt,
                        passwordHash: PasswordHasher.hash(password: account.password, salt: salt),
                        isAdmin: account.isAdmin
                    )
                    context.insert(user)
                }
                try context.save()
            }
        } catch {
            assertionFailure("Не удалось создать стартовые аккаунты: \(error)")
        }

    }
}
