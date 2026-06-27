import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Bindable var settings: AppSettings
    @State private var _baseSalaryText = ""

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
                            if let salary = MoneyFormatter.decimal(from: value) {
                                settings.baseSalary = salary
                            }
                        }
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
}
