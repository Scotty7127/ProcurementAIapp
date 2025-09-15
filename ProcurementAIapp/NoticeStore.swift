//
//  NoticeStore.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 04/09/2025.
//

import Foundation
import CloudKit

class NoticeStore: ObservableObject {
    @Published var notices: [Notice] = []           // local drafts
    @Published var bulletinBoard: [Notice] = []     // shared board via CloudKit

    private var database = CKContainer.default().publicCloudDatabase

    init() {
        fetchBulletinBoard()
        subscribeToChanges()
    }

    // MARK: - Drafts
    func saveDraft(_ notice: Notice) {
        notices.append(notice)
    }

    func deleteDraft(at offsets: IndexSet) {
        notices.remove(atOffsets: offsets)
    }

    // MARK: - Posting to CloudKit
    func postNotice(_ notice: Notice) {
        let record = notice.toRecord()
        database.save(record) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit save error: \(error.localizedDescription)")
                } else {
                    print("✅ Notice posted to CloudKit")
                    // Refresh board after posting
                    self.fetchBulletinBoard()
                    // Also remove from local drafts if present
                    if let index = self.notices.firstIndex(where: { $0.id == notice.id }) {
                        self.notices.remove(at: index)
                    }
                }
            }
        }
    }

    // MARK: - Fetch Bulletin Board
    func fetchBulletinBoard() {
        let query = CKQuery(recordType: Notice.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]

        let operation = CKQueryOperation(query: query)
        var fetched: [Notice] = []

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                if let notice = Notice(record: record) {
                    fetched.append(notice)
                }
            case .failure(let error):
                print("❌ Error fetching record \(recordID): \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.bulletinBoard = fetched
                    print("✅ Bulletin board updated: \(fetched.count) notices")
                case .failure(let error):
                    print("❌ CloudKit query error: \(error.localizedDescription)")
                }
            }
        }

        database.add(operation)
    }

    // MARK: - Delete from CloudKit
    func deleteNoticeFromBoard(_ notice: Notice) {
        let recordID = CKRecord.ID(recordName: notice.id.uuidString)
        database.delete(withRecordID: recordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit delete error: \(error.localizedDescription)")
                } else {
                    self.fetchBulletinBoard()
                }
            }
        }
    }

    // MARK: - CloudKit Subscriptions
    private func subscribeToChanges() {
        let subscriptionID = "notice-changes"

        database.fetch(withSubscriptionID: subscriptionID) { _, fetchError in
            if fetchError == nil {
                print("✅ Already subscribed to CloudKit changes")
                return
            }

            let subscription = CKQuerySubscription(
                recordType: Notice.recordType,
                predicate: NSPredicate(value: true),
                subscriptionID: subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
            )

            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true // silent push
            subscription.notificationInfo = info

            self.database.save(subscription) { _, error in
                if let error = error {
                    print("⚠️ Subscription error: \(error.localizedDescription)")
                } else {
                    print("✅ Subscribed to CloudKit changes")
                }
            }
        }
    }
}
