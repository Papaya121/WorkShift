import Foundation

enum ShiftAdjustmentKind: String, Codable {
    case income
    case expense

    var defaultTitle: String {
        switch self {
        case .income:
            return "Доход"
        case .expense:
            return "Расход"
        }
    }
}

struct ShiftAdjustment: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: ShiftAdjustmentKind
    var title: String
    var amount: Decimal

    init(
        id: UUID = UUID(),
        kind: ShiftAdjustmentKind,
        title: String? = nil,
        amount: Decimal = 0
    ) {
        self.id = id
        self.kind = kind
        self.title = title ?? kind.defaultTitle
        self.amount = amount
    }

    var signedAmount: Decimal {
        switch kind {
        case .income:
            return amount
        case .expense:
            return -amount
        }
    }
}
