import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let shift: Shift?
    let settings: AppSettings

    private var status: ShiftRevenueStatus {
        ShiftStatusResolver.revenueStatus(for: shift, on: date, settings: settings)
    }

    var body: some View {
        VStack(spacing: 5) {
            Text("\(DateHelper.calendar.component(.day, from: date))")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            if let shift, shift.isWorkDay {
                switch status {
                case .filled:
                    Text(MoneyFormatter.calendarString(shift.income))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                case .missingRevenue:
                    Label("нет", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                case .planned, .todayPending, .notWorkDay:
                    EmptyView()
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .aspectRatio(0.82, contentMode: .fit)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(DateHelper.calendar.isDateInToday(date) ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .overlay(alignment: .topTrailing) {
            if shift?.hasNote == true {
                Image(systemName: "note.text")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .accessibilityLabel("Есть заметка")
            }
        }
    }

    private var backgroundColor: Color {
        if let shift, shift.isWorkDay, let legend = settings.legend(id: shift.legendID) {
            return color(for: legend).opacity(0.28)
        }

        switch status {
        case .notWorkDay:
            return Color(.secondarySystemGroupedBackground)
        case .filled:
            return Color.green.opacity(0.22)
        case .missingRevenue:
            return Color.orange.opacity(0.18)
        case .planned, .todayPending:
            return Color.blue.opacity(0.18)
        }
    }

    private func color(for legend: ShiftLegend) -> Color {
        Color(
            red: Double(legend.red) / 255,
            green: Double(legend.green) / 255,
            blue: Double(legend.blue) / 255
        )
    }
}
