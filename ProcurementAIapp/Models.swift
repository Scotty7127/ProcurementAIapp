//
//  Models.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 04/09/2025.
//

import Foundation
import CloudKit

struct FormField: Identifiable, Codable {
    var id: UUID = UUID()    // ✅ stable identity
    var key: String
    var value: String
    var tooltip: String?
}

enum NoticeType: String, CaseIterable, Identifiable, Codable {
    case plannedProcurement = "Planned Procurement Notice"
    case tender = "Tender Notice"
    case pinCompetition = "PIN as Call for Competition"
    case transparency = "Transparency Notice"
    case award = "Contract Award Notice"
    case change = "Contract Change Notice"
    case termination = "Contract Termination Notice"
    case pipeline = "Pipeline Notice"
    case lowValue = "Low Value Notice"

    var id: String { rawValue }

    var requiredFields: [FormField] {
        [
            FormField(key: "Title", value: "", tooltip: "Enter the procurement title"),
            FormField(key: "Authority", value: "", tooltip: "Name of the contracting authority"),
            FormField(key: "Value", value: "", tooltip: "Estimated contract value"),
            FormField(key: "Deadline", value: "", tooltip: "Submission deadline")
        ]
    }
}

struct Notice: Identifiable, Codable {
    var id: UUID = UUID()     // ✅ stable identity
    var type: NoticeType
    var fields: [FormField]
    var createdDate: Date = Date()

    var displayTitle: String {
        if let titleField = fields.first(where: { $0.key.lowercased() == "title" && !$0.value.isEmpty }) {
            return "\(titleField.value) (\(type.rawValue))"
        } else {
            return type.rawValue
        }
    }
}

// MARK: - CloudKit Support
extension Notice {
    static let recordType = "Notice"

    init?(record: CKRecord) {
        guard
            let typeString = record["type"] as? String,
            let type = NoticeType(rawValue: typeString),
            let createdDate = record["createdDate"] as? Date,
            let fieldsData = record["fields"] as? Data,
            let fields = try? JSONDecoder().decode([FormField].self, from: fieldsData)
        else {
            print("❌ Failed to decode CKRecord into Notice. Raw record: \(record)")
            return nil
        }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.type = type
        self.fields = fields
        self.createdDate = createdDate

        print("✅ Successfully decoded Notice from CloudKit: \(self.displayTitle)")
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Notice.recordType, recordID: recordID)
        record["type"] = type.rawValue as CKRecordValue
        record["createdDate"] = createdDate as CKRecordValue
        if let fieldsData = try? JSONEncoder().encode(fields) {
            record["fields"] = fieldsData as CKRecordValue
        }
        print("📤 Saving Notice to CloudKit: \(displayTitle)")
        return record
    }
}
