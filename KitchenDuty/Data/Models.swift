import Foundation
import SwiftData

@Model
final class UserAccount {
    @Attribute(.unique) var username: String
    var userID: UUID
    var displayName: String
    var salt: String
    var passwordHash: String
    var isAdmin: Bool
    var createdAt: Date

    init(
        userID: UUID = UUID(),
        username: String,
        displayName: String,
        salt: String,
        passwordHash: String,
        isAdmin: Bool = false,
        createdAt: Date = Date()
    ) {
        self.userID = userID
        self.username = username
        self.displayName = displayName
        self.salt = salt
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
        self.createdAt = createdAt
    }
}

@Model
final class DutySlot {
    var slotID: UUID
    var weekKey: Int
    var weekday: Int
    var userID: UUID
    var dish: String = ""

    init(
        slotID: UUID = UUID(),
        weekKey: Int,
        weekday: Int,
        userID: UUID,
        dish: String = ""
    ) {
        self.slotID = slotID
        self.weekKey = weekKey
        self.weekday = weekday
        self.userID = userID
        self.dish = dish
    }
}

@Model
final class RatingRecord {
    var ratingID: UUID
    var fromUserID: UUID
    var toUserID: UUID
    var stars: Int
    var comment: String
    var weekKey: Int
    var weekday: Int = 0
    var createdAt: Date

    init(
        ratingID: UUID = UUID(),
        fromUserID: UUID,
        toUserID: UUID,
        stars: Int,
        comment: String,
        weekKey: Int,
        weekday: Int,
        createdAt: Date = Date()
    ) {
        self.ratingID = ratingID
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.stars = stars
        self.comment = comment
        self.weekKey = weekKey
        self.weekday = weekday
        self.createdAt = createdAt
    }
}
