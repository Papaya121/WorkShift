import SwiftUI

struct ShiftListScreen: View {
    let shifts: [Shift]
    let settings: AppSettings
    @Binding var selectedMonth: Date
    @Binding var editingDraft: ShiftDraft?

    private var workShifts: [Shift] {
        let interval = DateHelper.monthInterval(for: selectedMonth)
        return shifts
            .filter { $0.isWorkDay && $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthPickerBar(month: $selectedMonth)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                if workShifts.isEmpty {
                    EmptyStateView(title: "Нет рабочих смен", systemImage: "calendar.badge.exclamationmark")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(workShifts) { shift in
                        Button {
                            editingDraft = ShiftDraft(shift: shift)
                        } label: {
                            ShiftRow(shift: shift, settings: settings)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .monthSwipeGesture(month: $selectedMonth)
            .animation(.easeInOut(duration: 0.22), value: selectedMonth)
            .navigationTitle("Список смен")
        }
    }
}
