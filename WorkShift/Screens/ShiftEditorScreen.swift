import SwiftUI
import SwiftData

struct ShiftEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let draft: ShiftDraft
    @State private var _isWorkDay = true
    @State private var _percentRate = 5
    @State private var _baseSalary = Decimal(2000)
    @State private var _revenueText = ""

    private var parsedRevenue: Decimal? {
        MoneyFormatter.decimal(from: _revenueText)
    }

    private var calculatedIncome: Decimal {
        guard let parsedRevenue else { return _baseSalary }
        return ShiftCalculator.income(baseSalary: _baseSalary, revenue: parsedRevenue, percentRate: _percentRate)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Дата")
                    Spacer()
                    Text(DateHelper.fullDate(draft.date))
                        .foregroundStyle(.secondary)
                }

                Toggle("Рабочий день", isOn: $_isWorkDay)
            }

            if _isWorkDay {
                Section("Начисления") {
                    Picker("Процент", selection: $_percentRate) {
                        Text("5%").tag(5)
                        Text("10%").tag(10)
                    }
                    .pickerStyle(.segmented)

                    TextField("Выручка", text: $_revenueText)
                        .keyboardType(.decimalPad)

                    StatRow(title: "Оклад", value: MoneyFormatter.string(_baseSalary))
                    StatRow(title: "Процент", value: parsedRevenue.map { MoneyFormatter.string(ShiftCalculator.percentAmount(revenue: $0, percentRate: _percentRate)) } ?? "не заполнено")
                    StatRow(title: "Итого", value: MoneyFormatter.string(calculatedIncome), valueColor: .accentColor)
                }

                if draft.shift != nil {
                    Section {
                        Button("Удалить смену", role: .destructive) {
                            deleteShift()
                        }
                    }
                }
            }
        }
        .navigationTitle("Смена")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
        .onAppear {
            loadDraft()
        }
    }

    private func loadDraft() {
        _isWorkDay = draft.isWorkDay
        _percentRate = draft.percentRate
        _baseSalary = draft.baseSalary
        _revenueText = draft.revenue.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
    }

    private func save() {
        if let shift = draft.shift {
            shift.date = DateHelper.calendar.startOfDay(for: draft.date)
            shift.isWorkDay = _isWorkDay
            shift.revenue = _isWorkDay ? parsedRevenue : nil
            shift.percentRate = _percentRate
            shift.baseSalary = _baseSalary
            shift.updatedAt = Date()
        } else if _isWorkDay {
            let shift = Shift(
                date: draft.date,
                isWorkDay: true,
                revenue: parsedRevenue,
                percentRate: _percentRate,
                baseSalary: _baseSalary
            )
            modelContext.insert(shift)
        }

        dismiss()
    }

    private func deleteShift() {
        if let shift = draft.shift {
            modelContext.delete(shift)
        }

        dismiss()
    }
}
