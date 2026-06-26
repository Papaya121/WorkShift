import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Environment(\.modelContext) private var modelContext
    let shifts: [Shift]
    let settings: AppSettings
    @Binding var selectedMonth: Date
    @Binding var editingDraft: ShiftDraft?
    let onShiftChanged: () -> Void

    private let _columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let _weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private var workShifts: [Shift] {
        let interval = DateHelper.monthInterval(for: selectedMonth)
        return shifts.filter { $0.isWorkDay && $0.date >= interval.start && $0.date < interval.end }
    }

    private var totalIncome: Decimal {
        workShifts.reduce(Decimal(0)) { $0 + $1.income }
    }

    private var completedWorkShiftCount: Int {
        let today = DateHelper.calendar.startOfDay(for: Date())
        return workShifts.filter { DateHelper.calendar.startOfDay(for: $0.date) <= today }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    MonthPickerBar(month: $selectedMonth)

                    LazyVGrid(columns: _columns, spacing: 8) {
                        ForEach(_weekdays, id: \.self) { weekday in
                            Text(weekday)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(0..<DateHelper.leadingEmptyDays(for: selectedMonth), id: \.self) { _ in
                            Color.clear
                                .aspectRatio(0.82, contentMode: .fit)
                        }

                        ForEach(DateHelper.daysInMonth(for: selectedMonth), id: \.self) { date in
                            CalendarDayCell(date: date, shift: shift(on: date), settings: settings)
                                .onTapGesture {
                                    editingDraft = draft(on: date)
                                }
                                .contextMenu {
                                    Button("Редактировать") {
                                        editingDraft = draft(on: date)
                                    }
                                    Button(shift(on: date)?.isWorkDay == true ? "Сделать нерабочим" : "Сделать рабочим") {
                                        toggleWorkDay(on: date)
                                    }
                                }
                        }
                    }

                    CalendarMonthSummary(
                        workShiftCount: workShifts.count,
                        totalIncome: totalIncome,
                        completedWorkShiftCount: completedWorkShiftCount
                    )
                }
                .padding()
                .animation(.easeInOut(duration: 0.22), value: selectedMonth)
            }
            .monthSwipeGesture(month: $selectedMonth)
            .navigationTitle("Календарь")
        }
    }

    private func shift(on date: Date) -> Shift? {
        shifts.first { DateHelper.isSameDay($0.date, date) }
    }

    private func draft(on date: Date) -> ShiftDraft {
        if let shift = shift(on: date) {
            return ShiftDraft(shift: shift)
        }

        return ShiftDraft(date: date, settings: settings)
    }

    private func existingOrNewShift(on date: Date) -> Shift {
        if let shift = shift(on: date) {
            return shift
        }

        let shift = Shift(
            date: date,
            isWorkDay: true,
            percentRate: settings.defaultPercentRate,
            baseSalary: settings.baseSalary
        )
        modelContext.insert(shift)
        return shift
    }

    private func toggleWorkDay(on date: Date) {
        if let shift = shift(on: date), shift.isWorkDay {
            modelContext.delete(shift)
        } else {
            let shift = existingOrNewShift(on: date)
            shift.isWorkDay = true
            shift.updatedAt = Date()
        }
        onShiftChanged()
    }
}

struct CalendarMonthSummary: View {
    let workShiftCount: Int
    let totalIncome: Decimal
    let completedWorkShiftCount: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Итог месяца")
                    .font(.headline)
                Spacer()
                Text(MoneyFormatter.string(totalIncome))
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }

            HStack(spacing: 10) {
                summaryItem(title: "Отработано", value: "\(completedWorkShiftCount)")
                summaryItem(title: "Смен", value: "\(workShiftCount)")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
