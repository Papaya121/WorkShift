import SwiftUI

struct MonthPickerBar: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(DateHelper.monthTitle(month))
                .font(.headline)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
    }

    private func changeMonth(by value: Int) {
        month = DateHelper.calendar.date(byAdding: .month, value: value, to: month) ?? month
    }
}
