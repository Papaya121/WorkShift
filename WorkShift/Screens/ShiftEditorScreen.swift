import SwiftUI
import SwiftData

struct ShiftEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let draft: ShiftDraft
    let settings: AppSettings
    let onSaved: () -> Void
    @State private var _isWorkDay = true
    @State private var _percentRate = 5
    @State private var _baseSalary = Decimal(2000)
    @State private var _revenueText = ""
    @State private var _noteText = ""
    @State private var _legendID: UUID?

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
                        .onChange(of: _revenueText) { _, value in
                            sanitizeRevenueText(value)
                        }

                    StatRow(title: "Оклад", value: MoneyFormatter.string(_baseSalary))
                    StatRow(title: "Процент", value: parsedRevenue.map { MoneyFormatter.string(ShiftCalculator.percentAmount(revenue: $0, percentRate: _percentRate)) } ?? "не заполнено")
                    StatRow(title: "Итого", value: MoneyFormatter.string(calculatedIncome), valueColor: .accentColor)
                }

                if !settings.shiftLegends.isEmpty {
                    Section("Легенда") {
                        Picker("Выбрать", selection: $_legendID) {
                            Text("Без легенды").tag(Optional<UUID>.none)

                            ForEach(settings.shiftLegends) { legend in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(color(for: legend))
                                        .frame(width: 12, height: 12)
                                    Text(legend.title)
                                }
                                .tag(Optional(legend.id))
                            }
                        }

                        selectedLegendColorSwatch
                    }
                }
            }

            Section("Заметка") {
                TextEditor(text: $_noteText)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if _noteText.isEmpty {
                            Text("Введите заметку")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            if draft.shift != nil {
                Section {
                    Button("Удалить день", role: .destructive) {
                        deleteShift()
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
        _noteText = draft.note
        _legendID = draft.legendID
    }

    private func save() {
        let note = normalizedNote()

        if let shift = draft.shift {
            guard _isWorkDay else {
                if let note {
                    shift.date = DateHelper.calendar.startOfDay(for: draft.date)
                    shift.isWorkDay = false
                    shift.revenue = nil
                    shift.note = note
                    shift.legendID = nil
                    shift.updatedAt = Date()
                } else {
                    modelContext.delete(shift)
                }
                onSaved()
                dismiss()
                return
            }

            shift.date = DateHelper.calendar.startOfDay(for: draft.date)
            shift.isWorkDay = true
            shift.revenue = parsedRevenue
            shift.note = note
            shift.legendID = _legendID
            shift.percentRate = _percentRate
            shift.baseSalary = _baseSalary
            shift.updatedAt = Date()
        } else if _isWorkDay || note != nil {
            let shift = Shift(
                date: draft.date,
                isWorkDay: _isWorkDay,
                revenue: _isWorkDay ? parsedRevenue : nil,
                note: note,
                legendID: _isWorkDay ? _legendID : nil,
                percentRate: _percentRate,
                baseSalary: _baseSalary
            )
            modelContext.insert(shift)
        }

        onSaved()
        dismiss()
    }

    private func sanitizeRevenueText(_ value: String) {
        let sanitized = MoneyFormatter.sanitizedInput(value)
        guard sanitized != value else { return }
        _revenueText = sanitized
    }

    private func normalizedNote() -> String? {
        let trimmedNote = _noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNote.isEmpty ? nil : _noteText
    }

    private func color(for legend: ShiftLegend) -> Color {
        Color(
            red: Double(legend.red) / 255,
            green: Double(legend.green) / 255,
            blue: Double(legend.blue) / 255
        )
    }

    @ViewBuilder
    private var selectedLegendColorSwatch: some View {
        if let legend = settings.legend(id: _legendID) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color(for: legend))
                .frame(maxWidth: .infinity, minHeight: 28)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private func deleteShift() {
        if let shift = draft.shift {
            modelContext.delete(shift)
        }

        onSaved()
        dismiss()
    }
}
