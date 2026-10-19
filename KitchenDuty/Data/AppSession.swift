import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    private let storageKey = "kitchenduty.currentUserId"

    var currentUserId: UUID? {
        didSet { persist() }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey) {
            currentUserId = UUID(uuidString: raw)
        }
    }

    func signIn(userId: UUID) {
        currentUserId = userId
    }

    func signOut() {
        currentUserId = nil
    }

    private func persist() {
        if let currentUserId {
            UserDefaults.standard.set(currentUserId.uuidString, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}
