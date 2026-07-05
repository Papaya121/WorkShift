import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.date) private var shifts: [Shift]
    @Bindable var settings: AppSettings
    let onSettingsChanged: () -> Void
    @State private var _baseSalaryText = ""
    @State private var _isAddingLegend = false
    @State private var _isExportingBackup = false
    @State private var _isImportingBackup = false
    @State private var _isConfirmingImport = false
    @State private var _backupMessage: String?
    @State private var _pendingBackup: WorkShiftBackup?
    @State private var _editingLegendID: UUID?
    @State private var _legendTitleText = ""
    @State private var _legendColor = Color(red: 80.0 / 255, green: 160.0 / 255, blue: 255.0 / 255)

    private var reminderTime: Binding<Date> {
        Binding {
            var components = DateHelper.calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = settings.revenueReminderHour
            components.minute = settings.revenueReminderMinute
            return DateHelper.calendar.date(from: components) ?? Date()
        } set: { date in
            let components = DateHelper.calendar.dateComponents([.hour, .minute], from: date)
            settings.revenueReminderHour = components.hour ?? 22
            settings.revenueReminderMinute = components.minute ?? 20
            onSettingsChanged()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Новые смены") {
                    Picker("Процент по умолчанию", selection: $settings.defaultPercentRate) {
                        Text("5%").tag(5)
                        Text("10%").tag(10)
                    }
                    .pickerStyle(.segmented)

                    TextField("Оклад", text: $_baseSalaryText)
                        .keyboardType(.decimalPad)
                        .onChange(of: _baseSalaryText) { _, value in
                            updateBaseSalary(from: value)
                        }
                }

                Section("Выручка") {
                    DatePicker("Ожидать после", selection: reminderTime, displayedComponents: .hourAndMinute)
                }

                Section("Валюта") {
                    HStack {
                        Text("Символ")
                        Spacer()
                        Text(settings.currencySymbol)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        _isExportingBackup = true
                    } label: {
                        Label("Экспортировать", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        _isImportingBackup = true
                    } label: {
                        Label("Импортировать", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Сохранения")
                } footer: {
                    Text("Экспорт сохранит смены и настройки в JSON-файл. Импорт заменит текущие данные данными из выбранного файла.")
                }

                Section {
                    if settings.shiftLegends.isEmpty {
                        Text("Легенды не добавлены")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(settings.shiftLegends) { legend in
                            HStack {
                                Button {
                                    editLegend(legend)
                                } label: {
                                    HStack(spacing: 10) {
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(color(for: legend))
                                            .frame(width: 28, height: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(legend.title)
                                                .foregroundStyle(.primary)
                                            Text("RGB \(legend.red), \(legend.green), \(legend.blue)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)

                                Button(role: .destructive) {
                                    deleteLegend(legend)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Легенда календаря")
                        Spacer()
                        Button {
                            resetLegendDraft()
                            _isAddingLegend = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel("Добавить легенду")
                    }
                }
            }
            .navigationTitle("Настройки")
            .onAppear {
                _baseSalaryText = NSDecimalNumber(decimal: settings.baseSalary).stringValue
            }
            .sheet(isPresented: $_isAddingLegend) {
                NavigationStack {
                    Form {
                        Section("Подпись") {
                            TextField("Например: Отпуск", text: $_legendTitleText)
                        }

                        Section("Цвет") {
                            ColorPicker("Цвет", selection: $_legendColor, supportsOpacity: false)
                            
                            HStack {
                                Text("Предпросмотр")
                                Spacer()
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(draftLegendColor)
                                    .frame(width: 44, height: 28)
                            }

                            Text("RGB \(draftLegendRGB.red), \(draftLegendRGB.green), \(draftLegendRGB.blue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle(_editingLegendID == nil ? "Новая легенда" : "Редактировать")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                closeLegendEditor()
                            } label: {
                                Text("Отмена")
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                saveLegend()
                            } label: {
                                Text(_editingLegendID == nil ? "Добавить" : "Готово")
                            }
                            .disabled(!canAddLegend)
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $_isExportingBackup,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFilename
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $_isImportingBackup,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Импорт сохранения", isPresented: $_isConfirmingImport, presenting: _pendingBackup) { backup in
                Button("Заменить данные", role: .destructive) {
                    applyBackup(backup)
                }
                Button("Отмена", role: .cancel) {
                    _pendingBackup = nil
                }
            } message: { backup in
                Text("Будут заменены текущие смены и настройки. В файле: \(backup.shifts.count) смен.")
            }
            .alert("Сохранения", isPresented: backupMessageBinding) {
                Button("OK", role: .cancel) {
                    _backupMessage = nil
                }
            } message: {
                Text(_backupMessage ?? "")
            }
        }
    }

    @MainActor private var backupDocument: WorkShiftBackupDocument {
        WorkShiftBackupDocument(
            backup: WorkShiftBackup(
                exportedAt: Date(),
                settings: SettingsBackup(settings: settings),
                shifts: shifts.map(ShiftBackup.init)
            )
        )
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "WorkShift_\(formatter.string(from: Date()))"
    }

    private var backupMessageBinding: Binding<Bool> {
        Binding {
            _backupMessage != nil
        } set: { isPresented in
            if !isPresented {
                _backupMessage = nil
            }
        }
    }

    private func updateBaseSalary(from value: String) {
        let sanitized = MoneyFormatter.sanitizedInput(value)
        if sanitized != value {
            _baseSalaryText = sanitized
            return
        }

        if let salary = MoneyFormatter.decimal(from: sanitized) {
            settings.baseSalary = salary
        }
    }

    private var canAddLegend: Bool {
        !_legendTitleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var draftLegendColor: Color {
        _legendColor
    }

    private var draftLegendRGB: (red: Int, green: Int, blue: Int) {
        rgbComponents(from: _legendColor)
    }

    private func saveLegend() {
        guard canAddLegend else { return }

        let rgb = draftLegendRGB
        var legends = settings.shiftLegends

        if let _editingLegendID, let index = legends.firstIndex(where: { $0.id == _editingLegendID }) {
            legends[index].title = _legendTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
            legends[index].red = rgb.red
            legends[index].green = rgb.green
            legends[index].blue = rgb.blue
        } else {
            legends.append(
                ShiftLegend(
                    title: _legendTitleText.trimmingCharacters(in: .whitespacesAndNewlines),
                    red: rgb.red,
                    green: rgb.green,
                    blue: rgb.blue
                )
            )
        }

        settings.shiftLegends = legends
        closeLegendEditor()
    }

    private func deleteLegend(_ legend: ShiftLegend) {
        settings.shiftLegends = settings.shiftLegends.filter { $0.id != legend.id }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            _backupMessage = "Сохранение экспортировано."
        case .failure(let error):
            _backupMessage = "Не удалось экспортировать сохранение: \(error.localizedDescription)"
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBackup(from: url)
        case .failure(let error):
            _backupMessage = "Не удалось импортировать сохранение: \(error.localizedDescription)"
        }
    }

    private func importBackup(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            _pendingBackup = try WorkShiftBackupDocument.decodeBackup(from: data)
            _isConfirmingImport = true
        } catch {
            _backupMessage = "Не удалось прочитать файл: \(error.localizedDescription)"
        }
    }

    private func applyBackup(_ backup: WorkShiftBackup) {
        for shift in shifts {
            modelContext.delete(shift)
        }

        settings.id = backup.settings.id
        settings.defaultPercentRate = backup.settings.defaultPercentRate
        settings.baseSalary = backup.settings.baseSalary
        settings.currencySymbol = backup.settings.currencySymbol
        settings.revenueReminderHour = backup.settings.revenueReminderHour
        settings.revenueReminderMinute = backup.settings.revenueReminderMinute
        settings.shiftLegendsData = backup.settings.shiftLegendsData

        for shiftBackup in backup.shifts {
            modelContext.insert(shiftBackup.makeShift())
        }

        do {
            try modelContext.save()
            _pendingBackup = nil
            _backupMessage = "Сохранение импортировано."
            _baseSalaryText = NSDecimalNumber(decimal: settings.baseSalary).stringValue
            onSettingsChanged()
        } catch {
            _backupMessage = "Не удалось сохранить импорт: \(error.localizedDescription)"
        }
    }

    private func resetLegendDraft() {
        _editingLegendID = nil
        _legendTitleText = ""
        _legendColor = Color(red: 80.0 / 255, green: 160.0 / 255, blue: 255.0 / 255)
    }

    private func editLegend(_ legend: ShiftLegend) {
        _editingLegendID = legend.id
        _legendTitleText = legend.title
        _legendColor = color(for: legend)
        _isAddingLegend = true
    }

    private func closeLegendEditor() {
        _isAddingLegend = false
        _editingLegendID = nil
        _legendTitleText = ""
    }

    private func color(for legend: ShiftLegend) -> Color {
        Color(
            red: Double(legend.red) / 255,
            green: Double(legend.green) / 255,
            blue: Double(legend.blue) / 255
        )
    }

    private func rgbComponents(from color: Color) -> (red: Int, green: Int, blue: Int) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (
            red: clampedRGBValue(red),
            green: clampedRGBValue(green),
            blue: clampedRGBValue(blue)
        )
        #else
        return (80, 160, 255)
        #endif
    }

    private func clampedRGBValue(_ value: CGFloat) -> Int {
        min(255, max(0, Int((value * 255).rounded())))
    }
}
