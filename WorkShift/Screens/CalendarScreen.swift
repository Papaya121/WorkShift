import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Environment(\.modelContext) private var modelContext
    let shifts: [Shift]
    let settings: AppSettings
    @Binding var selectedMonth: Date
    @Binding var editingDraft: ShiftDraft?

    private let _columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let _weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

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
                            CalendarDayCell(date: date, shift: shift(on: date))
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
                }
                .padding()
            }
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
        let shift = existingOrNewShift(on: date)
        shift.isWorkDay.toggle()
        shift.updatedAt = Date()
    }
}
