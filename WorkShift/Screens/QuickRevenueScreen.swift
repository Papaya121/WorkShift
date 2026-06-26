import SwiftUI
import SwiftData

struct QuickRevenueScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var shift: Shift
    let onSaved: () -> Void
    @State private var _revenueText = ""

    private var revenue: Decimal? {
        MoneyFormatter.decimal(from: _revenueText)
    }

    private var income: Decimal {
        guard let revenue else { return shift.baseSalary }
        return ShiftCalculator.income(baseSalary: shift.baseSalary, revenue: revenue, percentRate: shift.percentRate)
    }

    var body: some View {
        Form {
            Section {
                Text(DateHelper.fullDate(shift.date))
                    .font(.headline)
                TextField("Выручка за сегодня", text: $_revenueText)
                    .keyboardType(.decimalPad)
                    .onChange(of: _revenueText) { _, value in
                        sanitizeRevenueText(value)
                    }
            }

            Section("Расчет") {
                StatRow(title: "Процент", value: "\(shift.percentRate)%")
                StatRow(title: "Оклад", value: MoneyFormatter.string(shift.baseSalary))
                StatRow(title: "Итого", value: MoneyFormatter.string(income), valueColor: .accentColor)
            }

            Section {
                Button("Сохранить выручку") {
                    shift.revenue = revenue
                    shift.updatedAt = Date()
                    onSaved()
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(revenue == nil)
            }
        }
        .navigationTitle("Выручка")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
    }

    private func sanitizeRevenueText(_ value: String) {
        let sanitized = MoneyFormatter.sanitizedInput(value)
        guard sanitized != value else { return }
        _revenueText = sanitized
    }
}
