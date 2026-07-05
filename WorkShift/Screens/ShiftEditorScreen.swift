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
    @State private var _adjustmentItems: [ShiftAdjustmentFormItem] = []
    @State private var _isShowingAdjustmentDialog = false

    private var parsedRevenue: Decimal? {
        MoneyFormatter.decimal(from: _revenueText)
    }

    private var parsedAdjustmentItems: [ShiftAdjustment] {
        _adjustmentItems.map { item in
            ShiftAdjustment(
                id: item.id,
                kind: item.kind,
                title: normalizedAdjustmentTitle(item),
                amount: MoneyFormatter.decimal(from: item.amountText) ?? 0
            )
        }
    }

    private var adjustmentTotal: Decimal {
        parsedAdjustmentItems.reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private var canSave: Bool {
        guard _isWorkDay else { return true }
        return _adjustmentItems.allSatisfy(isValidAdjustmentItem)
    }

    private var calculatedIncome: Decimal {
        guard let parsedRevenue else { return _baseSalary + adjustmentTotal }
        return ShiftCalculator.income(
            baseSalary: _baseSalary,
            revenue: parsedRevenue,
            percentRate: _percentRate,
            adjustmentsTotal: adjustmentTotal
        )
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
                    StatRow(title: "Расходы/доходы", value: MoneyFormatter.string(adjustmentTotal), valueColor: adjustmentTotal < 0 ? .red : .secondary)
                    StatRow(title: "Итого", value: MoneyFormatter.string(calculatedIncome), valueColor: .accentColor)
                }

                Section {
                    Button {
                        _isShowingAdjustmentDialog = true
                    } label: {
                        Label("Добавить расходы/доходы", systemImage: "plus.circle")
                    }

                    ForEach($_adjustmentItems) { $item in
                        adjustmentRow(item: $item)
                    }
                } footer: {
                    if !canSave {
                        Text("Заполните название и сумму для каждого дохода или расхода.")
                    }
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
                .disabled(!canSave)
            }
        }
        .onAppear {
            loadDraft()
        }
        .alert("Добавить", isPresented: $_isShowingAdjustmentDialog) {
            Button("Доход") {
                addAdjustment(kind: .income)
            }

            Button("Расход") {
                addAdjustment(kind: .expense)
            }

            Button("Отмена", role: .cancel) { }
        }
    }

    @MainActor private func loadDraft() {
        _isWorkDay = draft.isWorkDay
        _percentRate = draft.percentRate
        _baseSalary = draft.baseSalary
        _revenueText = draft.revenue.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        _noteText = draft.note
        _legendID = draft.legendID
        _adjustmentItems = draft.adjustmentItems.map(ShiftAdjustmentFormItem.init)
    }

    private func save() {
        guard canSave else { return }

        let note = normalizedNote()
        let adjustmentItems = parsedAdjustmentItems

        if let shift = draft.shift {
            guard _isWorkDay else {
                if let note {
                    shift.date = DateHelper.calendar.startOfDay(for: draft.date)
                    shift.isWorkDay = false
                    shift.revenue = nil
                    shift.note = note
                    shift.legendID = nil
                    shift.adjustmentItems = []
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
            shift.adjustmentItems = adjustmentItems
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
                adjustmentItemsData: nil,
                percentRate: _percentRate,
                baseSalary: _baseSalary
            )
            shift.adjustmentItems = _isWorkDay ? adjustmentItems : []
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

    private func sanitizeAdjustmentAmount(_ item: ShiftAdjustmentFormItem, value: String) {
        let sanitized = MoneyFormatter.sanitizedInput(value)
        guard sanitized != value,
              let index = _adjustmentItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        _adjustmentItems[index].amountText = sanitized
    }

    private func addAdjustment(kind: ShiftAdjustmentKind) {
        _adjustmentItems.append(ShiftAdjustmentFormItem(kind: kind))
    }

    private func deleteAdjustmentItem(id: UUID) {
        _adjustmentItems.removeAll { $0.id == id }
    }

    private func isValidAdjustmentItem(_ item: ShiftAdjustmentFormItem) -> Bool {
        !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (MoneyFormatter.decimal(from: item.amountText) ?? 0) > 0
    }

    private func normalizedAdjustmentTitle(_ item: ShiftAdjustmentFormItem) -> String {
        item.title.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func adjustmentRow(item: Binding<ShiftAdjustmentFormItem>) -> some View {
        HStack(spacing: 12) {
            TextField(adjustmentTitlePlaceholder(for: item.wrappedValue.kind), text: item.title)

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                TextField("0", text: item.amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 96)
                    .onChange(of: item.wrappedValue.amountText) { _, value in
                        sanitizeAdjustmentAmount(item.wrappedValue, value: value)
                    }

                Text("₽")
            }
            .foregroundStyle(item.wrappedValue.kind == .expense ? .red : .primary)

            Button(role: .destructive) {
                deleteAdjustmentItem(id: item.wrappedValue.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Удалить")
        }
    }

    private func adjustmentTitlePlaceholder(for kind: ShiftAdjustmentKind) -> String {
        switch kind {
        case .income:
            return "Название дохода"
        case .expense:
            return "Название расхода"
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

private struct ShiftAdjustmentFormItem: Identifiable {
    let id: UUID
    var kind: ShiftAdjustmentKind
    var title: String
    var amountText: String

    init(id: UUID = UUID(), kind: ShiftAdjustmentKind) {
        self.id = id
        self.kind = kind
        self.title = ""
        self.amountText = ""
    }

    init(adjustment: ShiftAdjustment) {
        self.id = adjustment.id
        self.kind = adjustment.kind
        self.title = adjustment.title
        self.amountText = NSDecimalNumber(decimal: adjustment.amount).stringValue
    }
}
