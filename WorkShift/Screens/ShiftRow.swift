import SwiftUI

struct ShiftRow: View {
    let shift: Shift
    let settings: AppSettings

    private var status: ShiftRevenueStatus {
        ShiftStatusResolver.revenueStatus(for: shift, on: shift.date, settings: settings)
    }

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

        switch status {
        case .planned:
            return "Плановая смена"
        case .todayPending:
            return "Смена сегодня"
        case .missingRevenue:
            return "Выручка не заполнена"
        case .filled, .notWorkDay:
            return ""
        }
    }

    private var revenueStatusColor: Color {
        switch status {
        case .filled:
            return .secondary
        case .planned, .todayPending:
            return .blue
        case .missingRevenue:
            return .orange
        case .notWorkDay:
            return .secondary
        }
    }
}
