import SwiftUI

struct StatisticsScreen: View {
    let shifts: [Shift]
    @Binding var selectedMonth: Date

    private var workShifts: [Shift] {
        let interval = DateHelper.monthInterval(for: selectedMonth)
        return shifts.filter { $0.isWorkDay && $0.date >= interval.start && $0.date < interval.end }
    }

    private var shiftsWithoutRevenue: [Shift] {
        workShifts.filter { $0.revenue == nil }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthPickerBar(month: $selectedMonth)
                }

                Section("Итоги") {
                    StatRow(title: "Рабочих смен", value: "\(workShifts.count)")
                    StatRow(title: "Сумма выручки", value: MoneyFormatter.string(totalRevenue))
                    StatRow(title: "Сумма процентов", value: MoneyFormatter.string(totalPercentAmount))
                    StatRow(title: "Сумма окладов", value: MoneyFormatter.string(totalBaseSalary))
                    StatRow(title: "Доход за месяц", value: MoneyFormatter.string(totalIncome), valueColor: .accentColor)
                }

                Section("Без выручки") {
                    if shiftsWithoutRevenue.isEmpty {
                        Text("Все рабочие смены заполнены")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(shiftsWithoutRevenue) { shift in
                            Text(DateHelper.fullDate(shift.date))
                        }
                    }
                }
            }
            .navigationTitle("Статистика")
        }
    }

    private var totalRevenue: Decimal {
        workShifts.reduce(Decimal(0)) { $0 + ($1.revenue ?? 0) }
    }

    private var totalPercentAmount: Decimal {
        workShifts.reduce(Decimal(0)) { $0 + $1.percentAmount }
    }

    private var totalBaseSalary: Decimal {
        workShifts.reduce(Decimal(0)) { $0 + $1.baseSalary }
    }

    private var totalIncome: Decimal {
        workShifts.reduce(Decimal(0)) { $0 + $1.income }
    }
}
