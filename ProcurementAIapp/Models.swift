//
//  Models.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 04/09/2025.
//

import Foundation
import CloudKit

// MARK: - Form Field

struct FormField: Identifiable, Codable {
    let id = UUID()
    let key: String
    var value: String
    var tooltip: String?
}

// MARK: - Notice Type

enum NoticeType: String, CaseIterable, Identifiable, Codable {
    case plannedProcurement = "Planned Procurement Notice"
    case tender = "Tender Notice"
    case transparency = "Transparency Notice"
    case contractAward = "Contract Award Notice"
    case contractChange = "Contract Change Notice"
    case contractTermination = "Contract Termination Notice"
    case pipeline = "Pipeline Notice"
    case lowValue = "Low Value Notice"

    var id: String { self.rawValue }

    var requiredFields: [FormField] {
        switch self {
        case .plannedProcurement:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Estimated Value", value: ""),
                FormField(key: "Authority", value: "")
            ]
        case .tender:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "CPV Code", value: ""),
                FormField(key: "Deadline", value: "")
            ]
        case .transparency:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Justification", value: "")
            ]
        case .contractAward:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Winner", value: ""),
                FormField(key: "Award Date", value: "")
            ]
        case .contractChange:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Change Description", value: "")
            ]
        case .contractTermination:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Termination Reason", value: "")
            ]
        case .pipeline:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Upcoming Date", value: "")
            ]
        case .lowValue:
            return [
                FormField(key: "Title", value: ""),
                FormField(key: "Amount", value: "")
            ]
        }
    }
}

// MARK: - Notice

struct Notice: Identifiable, Codable {
    var id: UUID
    var type: NoticeType
    var fields: [FormField]
    var createdDate: Date

    init(id: UUID = UUID(), type: NoticeType, fields: [FormField], createdDate: Date = Date()) {
        self.id = id
        self.type = type
        self.fields = fields
        self.createdDate = createdDate
    }

    var displayTitle: String {
        if let titleField = fields.first(where: { $0.key.lowercased() == "title" }),
           !titleField.value.isEmpty {
            return "\(titleField.value) (\(type.rawValue))"
        }
        return type.rawValue
    }
}

// MARK: - CloudKit Extension

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
            return nil
        }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.type = type
        self.fields = fields
        self.createdDate = createdDate
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Notice.recordType, recordID: recordID)
        record["type"] = type.rawValue as CKRecordValue
        record["createdDate"] = createdDate as CKRecordValue
        if let fieldsData = try? JSONEncoder().encode(fields) {
            record["fields"] = fieldsData as CKRecordValue
        }
        return record
    }
}
