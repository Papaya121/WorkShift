import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let shift: Shift?

    var body: some View {
        VStack(spacing: 5) {
            Text("\(DateHelper.calendar.component(.day, from: date))")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            if shift?.isWorkDay == true {
                if let shift, shift.hasRevenue {
                    Text(MoneyFormatter.calendarString(shift.income))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                } else if shouldShowMissingRevenueWarning {
                    Label("нет", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
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
    }

    private var backgroundColor: Color {
        guard shift?.isWorkDay == true else {
            return Color(.secondarySystemGroupedBackground)
        }

        if shift?.hasRevenue == true {
            return Color.green.opacity(0.22)
        }

        if shouldShowMissingRevenueWarning {
            return Color.orange.opacity(0.18)
        }

        return Color.blue.opacity(0.18)
    }

    private var shouldShowMissingRevenueWarning: Bool {
        guard shift?.isWorkDay == true, shift?.hasRevenue != true else { return false }

        let day = DateHelper.calendar.startOfDay(for: date)
        let today = DateHelper.calendar.startOfDay(for: Date())

        if day < today {
            return true
        }

        if day > today {
            return false
        }

        return isAfterRevenueCutoff
    }

    private var isAfterRevenueCutoff: Bool {
        let components = DateHelper.calendar.dateComponents([.hour, .minute], from: Date())
        guard let hour = components.hour, let minute = components.minute else { return false }
        return hour == 23 || (hour == 22 && minute >= 20)
    }
}
