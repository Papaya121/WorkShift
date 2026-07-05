import SwiftUI

struct StatisticsScreen: View {
    let shifts: [Shift]
    let settings: AppSettings
    @Binding var selectedMonth: Date

    private var workShifts: [Shift] {
        let interval = DateHelper.monthInterval(for: selectedMonth)
        return shifts.filter { $0.isWorkDay && $0.date >= interval.start && $0.date < interval.end }
    }

    private var shiftsWithNotes: [Shift] {
        let interval = DateHelper.monthInterval(for: selectedMonth)
        return shifts
            .filter { $0.hasNote && $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date < $1.date }
    }

    private var shiftsWithoutRevenue: [Shift] {
        workShifts.filter { $0.revenue == nil }.sorted { $0.date < $1.date }
    }

    private var pastShiftsWithoutRevenue: [Shift] {
        shiftsWithoutRevenue.filter { startOfDay($0.date) < today }
    }

    private var todayShiftsWithoutRevenue: [Shift] {
        shiftsWithoutRevenue.filter { DateHelper.calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    private var futureShiftsWithoutRevenue: [Shift] {
        shiftsWithoutRevenue.filter { startOfDay($0.date) > today }
    }

    private var today: Date {
        DateHelper.calendar.startOfDay(for: Date())
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

                if !legendIncomeRows.isEmpty {
                    Section("По легендам") {
                        ForEach(legendIncomeRows) { row in
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(row.color)
                                    .frame(width: 20, height: 20)

                                Text(row.title)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(MoneyFormatter.string(row.income))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                Section("Без выручки") {
                    if shiftsWithoutRevenue.isEmpty {
                        Text("Все рабочие смены заполнены")
                            .foregroundStyle(.secondary)
                    } else {
                        StatRow(title: "Прошедшие", value: "\(pastShiftsWithoutRevenue.count)", valueColor: pastShiftsWithoutRevenue.isEmpty ? .secondary : .orange)
                        StatRow(title: "Сегодня", value: todayStatusText, valueColor: todayShiftsWithoutRevenue.isEmpty ? .secondary : todayStatusColor)
                        StatRow(title: "Плановые", value: "\(futureShiftsWithoutRevenue.count)", valueColor: futureShiftsWithoutRevenue.isEmpty ? .secondary : .blue)
                    }
                }

                if !pastShiftsWithoutRevenue.isEmpty {
                    Section("Прошедшие без выручки") {
                        ForEach(pastShiftsWithoutRevenue) { shift in
                            Text(DateHelper.fullDate(shift.date))
                        }
                    }
                }

                if !todayShiftsWithoutRevenue.isEmpty {
                    Section("Сегодня") {
                        ForEach(todayShiftsWithoutRevenue) { shift in
                            HStack {
                                Text(DateHelper.fullDate(shift.date))
                                Spacer()
                                Text(todayShiftStatusText(for: shift))
                                    .foregroundStyle(todayShiftStatusColor(for: shift))
                            }
                        }
                    }
                }

                if !futureShiftsWithoutRevenue.isEmpty {
                    Section("Плановые смены") {
                        ForEach(futureShiftsWithoutRevenue) { shift in
                            Text(DateHelper.fullDate(shift.date))
                        }
                    }
                }

                if !shiftsWithNotes.isEmpty {
                    Section("Заметки") {
                        ForEach(shiftsWithNotes) { shift in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(DateHelper.fullDate(shift.date))
                                    .font(.subheadline.weight(.semibold))
                                Text(shift.note ?? "")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .monthSwipeGesture(month: $selectedMonth)
            .animation(.easeInOut(duration: 0.22), value: selectedMonth)
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

    private var legendIncomeRows: [LegendIncomeRow] {
        settings.shiftLegends.map { legend in
            let income = workShifts
                .filter { $0.legendID == legend.id }
                .reduce(Decimal(0)) { $0 + $1.income }

            return LegendIncomeRow(
                id: legend.id,
                title: legend.title,
                color: color(for: legend),
                income: income
            )
        }
    }

    private var todayStatusText: String {
        guard let shift = todayShiftsWithoutRevenue.first else { return "0" }
        return todayShiftStatusText(for: shift)
    }

    private var todayStatusColor: Color {
        guard let shift = todayShiftsWithoutRevenue.first else { return .secondary }
        return todayShiftStatusColor(for: shift)
    }

    private func todayShiftStatusText(for shift: Shift) -> String {
        switch ShiftStatusResolver.revenueStatus(for: shift, on: shift.date, settings: settings) {
        case .missingRevenue:
            return "Выручка ожидается"
        case .todayPending:
            return "Смена сегодня"
        case .planned:
            return "Плановая смена"
        case .filled:
            return "Заполнено"
        case .notWorkDay:
            return "Не рабочий день"
        }
    }

    private func todayShiftStatusColor(for shift: Shift) -> Color {
        switch ShiftStatusResolver.revenueStatus(for: shift, on: shift.date, settings: settings) {
        case .missingRevenue:
            return .orange
        case .todayPending, .planned:
            return .blue
        case .filled, .notWorkDay:
            return .secondary
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        DateHelper.calendar.startOfDay(for: date)
    }

    private func color(for legend: ShiftLegend) -> Color {
        Color(
            red: Double(legend.red) / 255,
            green: Double(legend.green) / 255,
            blue: Double(legend.blue) / 255
        )
    }
}

private struct LegendIncomeRow: Identifiable {
    let id: UUID
    let title: String
    let color: Color
    let income: Decimal
}
