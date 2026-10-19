import SwiftUI

enum KitchenTheme {
    static let orange = Color(red: 0.93, green: 0.45, blue: 0.18)
    static let deepOrange = Color(red: 0.82, green: 0.32, blue: 0.10)
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.93)
    static let brown = Color(red: 0.32, green: 0.20, blue: 0.12)
    static let card = Color.white
}

enum WeekCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    static let weekdayNames = [
        "Понедельник", "Вторник", "Среда", "Четверг",
        "Пятница", "Суббота", "Воскресенье"
    ]

    static let weekdayShort = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    static func weekKey(for date: Date) -> Int {
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return year * 100 + week
    }

    static func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func dayDate(weekStart: Date, weekday: Int) -> Date {
        calendar.date(byAdding: .day, value: weekday - 1, to: weekStart) ?? weekStart
    }

    static func formatWeek(_ weekStart: Date) -> String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: weekStart)) — \(formatter.string(from: end))"
    }

    static func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
