import Foundation

enum DateHelper {
    static let calendar = Calendar.current
    private static let _russianLocale = Locale(identifier: "ru_RU")

    static func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func monthInterval(for date: Date) -> DateInterval {
        let start = startOfMonth(for: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    static func daysInMonth(for date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        let start = startOfMonth(for: date)
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    static func leadingEmptyDays(for date: Date) -> Int {
        let firstWeekday = calendar.component(.weekday, from: startOfMonth(for: date))
        return (firstWeekday + 5) % 7
    }

    static func isSameDay(_ firstDate: Date, _ secondDate: Date) -> Bool {
        calendar.isDate(firstDate, inSameDayAs: secondDate)
    }

    static func fullDate(_ date: Date) -> String {
        date.formatted(.dateTime.locale(_russianLocale).day().month(.wide).year())
    }

    static func monthTitle(_ date: Date) -> String {
        date.formatted(.dateTime.locale(_russianLocale).month(.wide).year())
    }
}
