import Foundation
import SwiftData

enum DutyService {
    static func clearPlaceholderWeekIfNeeded(weekKey: Int, slots: [DutySlot], context: ModelContext) {
        let week = slots.filter { $0.weekKey == weekKey }
        let allEmpty = week.allSatisfy { $0.dish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard week.count == 7, allEmpty else { return }
        week.forEach { context.delete($0) }
        try? context.save()
    }

    static func slot(weekKey: Int, weekday: Int, in slots: [DutySlot]) -> DutySlot? {
        slots.first { $0.weekKey == weekKey && $0.weekday == weekday }
    }

    static func mySlot(weekKey: Int, userID: UUID, in slots: [DutySlot]) -> DutySlot? {
        slots.first { $0.weekKey == weekKey && $0.userID == userID }
    }

    static func saveDuty(
        weekKey: Int,
        weekday: Int,
        dish: String,
        user: UserAccount,
        slots: [DutySlot],
        context: ModelContext
    ) throws {
        let name = dish.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw DutyError.emptyDish
        }
        guard (1...7).contains(weekday) else {
            throw DutyError.invalidDay
        }

        if let taken = slot(weekKey: weekKey, weekday: weekday, in: slots),
           taken.userID != user.userID {
            throw DutyError.dayTaken
        }

        if let mine = mySlot(weekKey: weekKey, userID: user.userID, in: slots) {
            mine.weekday = weekday
            mine.dish = name
        } else if let taken = slot(weekKey: weekKey, weekday: weekday, in: slots) {
            taken.userID = user.userID
            taken.dish = name
        } else {
            context.insert(
                DutySlot(weekKey: weekKey, weekday: weekday, userID: user.userID, dish: name)
            )
        }
        try context.save()
    }

    static func cancelDuty(weekKey: Int, userID: UUID, slots: [DutySlot], context: ModelContext) throws {
        guard let mine = mySlot(weekKey: weekKey, userID: userID, in: slots) else { return }
        context.delete(mine)
        try context.save()
    }

    static func rating(
        from fromUserID: UUID,
        to toUserID: UUID,
        weekKey: Int,
        weekday: Int,
        in ratings: [RatingRecord]
    ) -> RatingRecord? {
        ratings.first {
            $0.fromUserID == fromUserID
                && $0.toUserID == toUserID
                && $0.weekKey == weekKey
                && $0.weekday == weekday
        }
    }

    static func saveRating(
        from: UserAccount,
        to: UserAccount,
        weekKey: Int,
        weekday: Int,
        stars: Int,
        comment: String,
        ratings: [RatingRecord],
        context: ModelContext
    ) throws {
        guard from.userID != to.userID else { throw DutyError.selfRating }
        let value = min(5, max(1, stars))
        let text = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = rating(
            from: from.userID,
            to: to.userID,
            weekKey: weekKey,
            weekday: weekday,
            in: ratings
        ) {
            existing.stars = value
            existing.comment = text
        } else {
            context.insert(
                RatingRecord(
                    fromUserID: from.userID,
                    toUserID: to.userID,
                    stars: value,
                    comment: text,
                    weekKey: weekKey,
                    weekday: weekday
                )
            )
        }
        try context.save()
    }
}

enum DutyError: LocalizedError {
    case emptyDish
    case invalidDay
    case dayTaken
    case selfRating

    var errorDescription: String? {
        switch self {
        case .emptyDish:
            return "Напишите блюдо, которое будете готовить."
        case .invalidDay:
            return "Выберите день недели."
        case .dayTaken:
            return "Этот день уже занят. Выберите другой."
        case .selfRating:
            return "Нельзя оценить своё дежурство."
        }
    }
}
