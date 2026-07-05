import Foundation
import SwiftData

struct ShiftLegend: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var red: Int
    var green: Int
    var blue: Int

    init(id: UUID = UUID(), title: String, red: Int, green: Int, blue: Int) {
        self.id = id
        self.title = title
        self.red = red
        self.green = green
        self.blue = blue
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultPercentRate: Int
    var baseSalary: Decimal
    var currencySymbol: String
    var revenueReminderHour: Int = 22
    var revenueReminderMinute: Int = 20
    var shiftLegendsData: String?

    init(
        id: UUID = UUID(),
        defaultPercentRate: Int = 5,
        baseSalary: Decimal = 2000,
        currencySymbol: String = "₽",
        revenueReminderHour: Int = 22,
        revenueReminderMinute: Int = 20,
        shiftLegendsData: String? = nil
    ) {
        self.id = id
        self.defaultPercentRate = defaultPercentRate
        self.baseSalary = baseSalary
        self.currencySymbol = currencySymbol
        self.revenueReminderHour = revenueReminderHour
        self.revenueReminderMinute = revenueReminderMinute
        self.shiftLegendsData = shiftLegendsData
    }

    var shiftLegends: [ShiftLegend] {
        get {
            guard let data = shiftLegendsData?.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([ShiftLegend].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            shiftLegendsData = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    func legend(id: UUID?) -> ShiftLegend? {
        guard let id else { return nil }
        return shiftLegends.first { $0.id == id }
    }
}
