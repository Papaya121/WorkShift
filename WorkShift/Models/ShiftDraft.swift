import Foundation

struct ShiftDraft: Identifiable {
    let id: UUID
    let shift: Shift?
    let date: Date
    let isWorkDay: Bool
    let revenue: Decimal?
    let percentRate: Int
    let baseSalary: Decimal

    init(shift: Shift) {
        self.id = shift.id
        self.shift = shift
        self.date = shift.date
        self.isWorkDay = shift.isWorkDay
        self.revenue = shift.revenue
        self.percentRate = shift.percentRate
        self.baseSalary = shift.baseSalary
    }

    init(date: Date, settings: AppSettings) {
        self.id = UUID()
        self.shift = nil
        self.date = DateHelper.calendar.startOfDay(for: date)
        self.isWorkDay = true
        self.revenue = nil
        self.percentRate = settings.defaultPercentRate
        self.baseSalary = settings.baseSalary
    }
}
