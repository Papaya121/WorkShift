import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Bindable var settings: AppSettings
    @State private var _baseSalaryText = ""

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
            }
            .navigationTitle("Настройки")
            .onAppear {
                _baseSalaryText = NSDecimalNumber(decimal: settings.baseSalary).stringValue
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
}
