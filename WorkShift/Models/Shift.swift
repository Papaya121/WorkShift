import Foundation
import SwiftData

@Model
final class Shift {
    @Attribute(.unique) var id: UUID
    var date: Date
    var isWorkDay: Bool
    var revenue: Decimal?
    var note: String?
    var legendID: UUID?
    var percentRate: Int
    var baseSalary: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        isWorkDay: Bool = true,
        revenue: Decimal? = nil,
        note: String? = nil,
        legendID: UUID? = nil,
        percentRate: Int = 5,
        baseSalary: Decimal = 2000,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.isWorkDay = isWorkDay
        self.revenue = revenue
        self.note = note
        self.legendID = legendID
        self.percentRate = percentRate
        self.baseSalary = baseSalary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var income: Decimal {
        guard let revenue else { return baseSalary }
        return ShiftCalculator.income(baseSalary: baseSalary, revenue: revenue, percentRate: percentRate)
    }

    var percentAmount: Decimal {
        guard let revenue else { return 0 }
        return ShiftCalculator.percentAmount(revenue: revenue, percentRate: percentRate)
    }

    var hasRevenue: Bool {
        revenue != nil
    }

    var hasNote: Bool {
        guard let note else { return false }
        return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
