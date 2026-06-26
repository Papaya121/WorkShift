import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultPercentRate: Int
    var baseSalary: Decimal
    var currencySymbol: String
    var revenueReminderHour: Int = 22
    var revenueReminderMinute: Int = 20

    init(
        id: UUID = UUID(),
        defaultPercentRate: Int = 5,
        baseSalary: Decimal = 2000,
        currencySymbol: String = "₽",
        revenueReminderHour: Int = 22,
        revenueReminderMinute: Int = 20
    ) {
        self.id = id
        self.defaultPercentRate = defaultPercentRate
        self.baseSalary = baseSalary
        self.currencySymbol = currencySymbol
        self.revenueReminderHour = revenueReminderHour
        self.revenueReminderMinute = revenueReminderMinute
    }
}
