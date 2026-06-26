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
        withAnimation(.easeInOut(duration: 0.22)) {
            month = DateHelper.calendar.date(byAdding: .month, value: value, to: month) ?? month
        }
    }
}

extension View {
    func monthSwipeGesture(month: Binding<Date>) -> some View {
        gesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }

                    if value.translation.width < -50 {
                        changeMonth(month, by: 1)
                    } else if value.translation.width > 50 {
                        changeMonth(month, by: -1)
                    }
                }
        )
    }

    private func changeMonth(_ month: Binding<Date>, by value: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            month.wrappedValue = DateHelper.calendar.date(byAdding: .month, value: value, to: month.wrappedValue) ?? month.wrappedValue
        }
    }
}
