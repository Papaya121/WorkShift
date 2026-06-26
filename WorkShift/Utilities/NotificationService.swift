import Foundation
@preconcurrency import UserNotifications

struct ShiftNotificationPlan {
    let identifier: String
    let title: String
    let body: String
    let date: Date
}

struct NotificationDiagnostics {
    let authorizationStatus: String
    let pendingCount: Int
    let deliveredCount: Int
    let nearestDate: Date?
    let items: [NotificationDiagnosticItem]
}

struct NotificationDiagnosticItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let date: Date?
}

enum NotificationService {
    private static let _identifierPrefix = "workshift.notification."

    static func scheduleTestNotification() async -> Bool {
        guard await requestAuthorizationIfNeeded() else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Тест уведомлений"
        content.body = "Если ты это видишь, локальные уведомления работают."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(_identifierPrefix)test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
        }
    }

    static func diagnostics() async -> NotificationDiagnostics {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let authorizationText = authorizationStatusText(settings.authorizationStatus)
        let deliveredCount = await deliveredWorkShiftNotificationCount(center: center)

        return await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let workShiftRequests = requests.filter { $0.identifier.hasPrefix(_identifierPrefix) }
                let nearestDate = workShiftRequests
                    .compactMap { nextTriggerDate(for: $0.trigger) }
                    .sorted()
                    .first
                let items = workShiftRequests
                    .map { request in
                        NotificationDiagnosticItem(
                            id: request.identifier,
                            title: request.content.title,
                            body: request.content.body,
                            date: nextTriggerDate(for: request.trigger)
                        )
                    }
                    .sorted { first, second in
                        switch (first.date, second.date) {
                        case let (firstDate?, secondDate?):
                            return firstDate < secondDate
                        case (_?, nil):
                            return true
                        case (nil, _?):
                            return false
                        case (nil, nil):
                            return first.title < second.title
                        }
                    }

                continuation.resume(
                    returning: NotificationDiagnostics(
                        authorizationStatus: authorizationText,
                        pendingCount: workShiftRequests.count,
                        deliveredCount: deliveredCount,
                        nearestDate: nearestDate,
                        items: items
                    )
                )
            }
        }
    }

    private static func authorizationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "разрешены"
        case .provisional:
            return "тихо разрешены"
        case .ephemeral:
            return "временно разрешены"
        case .denied:
            return "запрещены"
        case .notDetermined:
            return "не запрошены"
        @unknown default:
            return "неизвестно"
        }
    }

    private static func nextTriggerDate(for trigger: UNNotificationTrigger?) -> Date? {
        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }

        if let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return Date().addingTimeInterval(intervalTrigger.timeInterval)
        }

        return nil
    }

    @MainActor
    static func refreshNotifications(shifts: [Shift], settings: AppSettings) {
        let plans = makePlans(shifts: shifts, settings: settings)

        Task {
            guard await requestAuthorizationIfNeeded() else { return }
            await replacePendingNotifications(with: plans)
        }
    }

    @MainActor
    private static func makePlans(shifts: [Shift], settings: AppSettings) -> [ShiftNotificationPlan] {
        let now = Date()
        let workShifts = shifts.filter { $0.isWorkDay }
        return workShifts.flatMap { shift in
            plans(for: shift, settings: settings)
        }
        .filter { $0.date > now }
        .sorted { $0.date < $1.date }
    }

    @MainActor
    private static func plans(for shift: Shift, settings: AppSettings) -> [ShiftNotificationPlan] {
        let day = DateHelper.calendar.startOfDay(for: shift.date)
        var plans: [ShiftNotificationPlan] = []

        if let tomorrowReminder = notificationDate(for: day, dayOffset: -1, hour: 18, minute: 0) {
            plans.append(
                ShiftNotificationPlan(
                    identifier: identifier(for: shift, kind: "tomorrow"),
                    title: "Завтра рабочий день",
                    body: "Не забудь, завтра у тебя смена.",
                    date: tomorrowReminder
                )
            )
        }

        if let goodShiftReminder = notificationDate(for: day, dayOffset: 0, hour: 10, minute: 40) {
            plans.append(
                ShiftNotificationPlan(
                    identifier: identifier(for: shift, kind: "goodShift"),
                    title: "Хорошей смены",
                    body: "Пусть смена пройдет спокойно и с хорошей выручкой.",
                    date: goodShiftReminder
                )
            )
        }

        if shift.revenue == nil,
           let revenueReminder = notificationDate(
               for: day,
               dayOffset: 0,
               hour: settings.revenueReminderHour,
               minute: settings.revenueReminderMinute + 30
           ) {
            plans.append(
                ShiftNotificationPlan(
                    identifier: identifier(for: shift, kind: "revenue"),
                    title: "Заполни выручку",
                    body: "Выручка за сегодняшнюю смену еще не внесена.",
                    date: revenueReminder
                )
            )
        }

        return plans
    }

    private static func notificationDate(for day: Date, dayOffset: Int, hour: Int, minute: Int) -> Date? {
        let baseDate = DateHelper.calendar.date(byAdding: .day, value: dayOffset, to: day) ?? day
        var components = DateHelper.calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = 0
        guard let date = DateHelper.calendar.date(from: components) else { return nil }
        return DateHelper.calendar.date(byAdding: .minute, value: minute, to: date)
    }

    private static func identifier(for shift: Shift, kind: String) -> String {
        "\(_identifierPrefix)\(kind).\(shift.id.uuidString)"
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func replacePendingNotifications(with plans: [ShiftNotificationPlan]) async {
        let center = UNUserNotificationCenter.current()
        let existingIdentifiers = await pendingWorkShiftNotificationIdentifiers(center: center)
        center.removePendingNotificationRequests(withIdentifiers: existingIdentifiers)

        for plan in plans {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default

            let components = DateHelper.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: plan.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private static func pendingWorkShiftNotificationIdentifiers(center: UNUserNotificationCenter) async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let identifiers = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(_identifierPrefix) }
                continuation.resume(returning: identifiers)
            }
        }
    }

    private static func deliveredWorkShiftNotificationCount(center: UNUserNotificationCenter) async -> Int {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                let count = notifications.filter { $0.request.identifier.hasPrefix(_identifierPrefix) }.count
                continuation.resume(returning: count)
            }
        }
    }
}
