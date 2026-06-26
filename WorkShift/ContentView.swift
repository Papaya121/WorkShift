import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Shift.date) private var shifts: [Shift]
    @Query private var settingsItems: [AppSettings]
    @State private var _selectedMonth = Date()
    @State private var _editingDraft: ShiftDraft?
    @State private var _quickShift: Shift?

    private var settings: AppSettings? {
        settingsItems.first
    }

    var body: some View {
        TabView {
            CalendarScreen(
                shifts: shifts,
                settings: currentSettings(),
                selectedMonth: $_selectedMonth,
                editingDraft: $_editingDraft
            )
            .tabItem {
                Label("Календарь", systemImage: "calendar")
            }

            ShiftListScreen(
                shifts: shifts,
                settings: currentSettings(),
                selectedMonth: $_selectedMonth,
                editingDraft: $_editingDraft
            )
            .tabItem {
                Label("Список", systemImage: "list.bullet.rectangle")
            }

            StatisticsScreen(shifts: shifts, settings: currentSettings(), selectedMonth: $_selectedMonth)
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar")
                }

            SettingsScreen(settings: currentSettings())
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
        .sheet(item: $_editingDraft) { draft in
            NavigationStack {
                ShiftEditorScreen(draft: draft)
            }
        }
        .sheet(item: $_quickShift) { shift in
            NavigationStack {
                QuickRevenueScreen(shift: shift)
            }
        }
        .onAppear {
            ensureSettings()
            showQuickInputIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            ensureSettings()
            showQuickInputIfNeeded()
        }
    }

    private func currentSettings() -> AppSettings {
        if let settings {
            return settings
        }

        let settings = AppSettings()
        modelContext.insert(settings)
        return settings
    }

    private func ensureSettings() {
        guard settings == nil else { return }
        modelContext.insert(AppSettings())
    }

    private func showQuickInputIfNeeded() {
        let settings = currentSettings()
        guard ShiftStatusResolver.isRevenueExpected(settings: settings) else { return }
        let today = DateHelper.calendar.startOfDay(for: Date())
        guard let shift = shifts.first(where: { DateHelper.isSameDay($0.date, today) }) else { return }
        guard shift.isWorkDay && shift.revenue == nil else { return }
        _quickShift = shift
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Shift.self, AppSettings.self], inMemory: true)
}
