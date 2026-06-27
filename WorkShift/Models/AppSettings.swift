import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultPercentRate: Int
    var baseSalary: Decimal
    var currencySymbol: String

    init(
        id: UUID = UUID(),
        defaultPercentRate: Int = 5,
        baseSalary: Decimal = 2000,
        currencySymbol: String = "₽"
    ) {
        self.id = id
        self.defaultPercentRate = defaultPercentRate
        self.baseSalary = baseSalary
        self.currencySymbol = currencySymbol
    }
}
