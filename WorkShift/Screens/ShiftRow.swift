import SwiftUI

struct ShiftRow: View {
    let shift: Shift

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateHelper.fullDate(shift.date))
                    .font(.headline)
                Spacer()
                Text("\(shift.percentRate)%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(revenueStatusText)
                    .foregroundStyle(revenueStatusColor)
                Spacer()
                Text(MoneyFormatter.string(shift.income))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private var revenueStatusText: String {
        if let revenue = shift.revenue {
            return "Выручка: \(MoneyFormatter.string(revenue))"
        }

        if isFutureShift {
            return "Плановая смена"
        }

        if isTodayBeforeRevenueCutoff {
            return "Смена сегодня"
        }

        return "Выручка не заполнена"
    }

    private var revenueStatusColor: Color {
        if shift.hasRevenue {
            return .secondary
        }

        return isFutureShift || isTodayBeforeRevenueCutoff ? .blue : .orange
    }

    private var isFutureShift: Bool {
        let shiftDay = DateHelper.calendar.startOfDay(for: shift.date)
        let today = DateHelper.calendar.startOfDay(for: Date())
        return shiftDay > today
    }

    private var isTodayBeforeRevenueCutoff: Bool {
        guard DateHelper.calendar.isDateInToday(shift.date) else { return false }
        let components = DateHelper.calendar.dateComponents([.hour, .minute], from: Date())
        guard let hour = components.hour, let minute = components.minute else { return false }
        return hour < 22 || (hour == 22 && minute < 20)
    }
}
