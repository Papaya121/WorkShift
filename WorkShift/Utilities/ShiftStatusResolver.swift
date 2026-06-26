import Foundation

enum ShiftRevenueStatus {
    case notWorkDay
    case filled
    case planned
    case todayPending
    case missingRevenue
}

enum ShiftStatusResolver {
    static func revenueStatus(for shift: Shift?, on date: Date, settings: AppSettings, now: Date = Date()) -> ShiftRevenueStatus {
        guard let shift, shift.isWorkDay else { return .notWorkDay }

        if shift.hasRevenue {
            return .filled
        }

        let day = DateHelper.calendar.startOfDay(for: date)
        let today = DateHelper.calendar.startOfDay(for: now)

        if day < today {
            return .missingRevenue
        }

        if day > today {
            return .planned
        }

        return isRevenueExpected(settings: settings, now: now) ? .missingRevenue : .todayPending
    }

    static func isRevenueExpected(settings: AppSettings, now: Date = Date()) -> Bool {
        let components = DateHelper.calendar.dateComponents([.hour, .minute], from: now)
        guard let hour = components.hour, let minute = components.minute else { return false }
        let currentMinutes = hour * 60 + minute
        let reminderMinutes = settings.revenueReminderHour * 60 + settings.revenueReminderMinute
        return currentMinutes >= reminderMinutes
    }
}
