import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct WorkShiftBackup: Codable {
    let exportedAt: Date
    let settings: SettingsBackup
    let shifts: [ShiftBackup]
}

struct SettingsBackup: Codable {
    let id: UUID
    let defaultPercentRate: Int
    let baseSalary: Decimal
    let currencySymbol: String
    let revenueReminderHour: Int
    let revenueReminderMinute: Int
    let shiftLegendsData: String?

    init(settings: AppSettings) {
        self.id = settings.id
        self.defaultPercentRate = settings.defaultPercentRate
        self.baseSalary = settings.baseSalary
        self.currencySymbol = settings.currencySymbol
        self.revenueReminderHour = settings.revenueReminderHour
        self.revenueReminderMinute = settings.revenueReminderMinute
        self.shiftLegendsData = settings.shiftLegendsData
    }
}

struct ShiftBackup: Codable {
    let id: UUID
    let date: Date
    let isWorkDay: Bool
    let revenue: Decimal?
    let note: String?
    let legendID: UUID?
    let adjustmentItemsData: String?
    let percentRate: Int
    let baseSalary: Decimal
    let createdAt: Date
    let updatedAt: Date

    init(shift: Shift) {
        self.id = shift.id
        self.date = shift.date
        self.isWorkDay = shift.isWorkDay
        self.revenue = shift.revenue
        self.note = shift.note
        self.legendID = shift.legendID
        self.adjustmentItemsData = shift.adjustmentItemsData
        self.percentRate = shift.percentRate
        self.baseSalary = shift.baseSalary
        self.createdAt = shift.createdAt
        self.updatedAt = shift.updatedAt
    }

    func makeShift() -> Shift {
        Shift(
            id: id,
            date: date,
            isWorkDay: isWorkDay,
            revenue: revenue,
            note: note,
            legendID: legendID,
            adjustmentItemsData: adjustmentItemsData,
            percentRate: percentRate,
            baseSalary: baseSalary,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case isWorkDay
        case revenue
        case note
        case legendID
        case adjustmentItemsData
        case percentRate
        case baseSalary
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.isWorkDay = try container.decode(Bool.self, forKey: .isWorkDay)
        self.revenue = try container.decodeIfPresent(Decimal.self, forKey: .revenue)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.legendID = try container.decodeIfPresent(UUID.self, forKey: .legendID)
        self.adjustmentItemsData = try container.decodeIfPresent(String.self, forKey: .adjustmentItemsData)
        self.percentRate = try container.decode(Int.self, forKey: .percentRate)
        self.baseSalary = try container.decode(Decimal.self, forKey: .baseSalary)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct WorkShiftBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    @MainActor init(backup: WorkShiftBackup) {
        self.data = (try? WorkShiftBackupDocument.encodeBackup(backup)) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }

    @MainActor static func encodeBackup(_ backup: WorkShiftBackup) throws -> Data {
        try encoder.encode(backup)
    }

    @MainActor static func decodeBackup(from data: Data) throws -> WorkShiftBackup {
        try decoder.decode(WorkShiftBackup.self, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
