//
//  Views.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 04/09/2025.
//

import SwiftUI

// MARK: - Notice Type Selector
struct NoticeTypeSelector: View {
    @ObservedObject var store: NoticeStore

    var body: some View {
        NavigationView {
            List(NoticeType.allCases) { type in
                NavigationLink(destination: NoticeFormView(store: store, noticeType: type)) {
                    Text(type.rawValue)
                }
            }
            .navigationTitle("Select Notice Type")
        }
    }
}

// MARK: - Notice Form
struct NoticeFormView: View {
    @ObservedObject var store: NoticeStore
    var noticeType: NoticeType
    @State private var fields: [FormField]

    init(store: NoticeStore, noticeType: NoticeType) {
        self.store = store
        self.noticeType = noticeType
        _fields = State(initialValue: noticeType.requiredFields)
    }

    var body: some View {
        Form {
            ForEach($fields) { $field in
                VStack(alignment: .leading) {
                    TextField(field.key, text: $field.value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let tip = field.tooltip {
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Button("Save Notice") {
                let newNotice = Notice(type: noticeType, fields: fields)
                store.notices.append(newNotice)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(noticeType.rawValue)
    }
}

// MARK: - Repository View
struct RepositoryView: View {
    @ObservedObject var store: NoticeStore
    @State private var showingShare = false
    @State private var exportData: Data?

    var body: some View {
        NavigationView {
            List {
                ForEach(store.notices) { notice in
                    VStack(alignment: .leading) {
                        Text(notice.displayTitle)
                            .font(.headline)
                        Text("Created: \(notice.createdDate.formatted())")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Button("Export JSON") {
                                if let data = try? JSONEncoder().encode(notice) {
                                    exportData = data
                                    showingShare = true
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Post") {
                                store.postNotice(notice)
                                if let index = store.notices.firstIndex(where: { $0.id == notice.id }) {
                                    store.notices.remove(at: index)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    store.notices.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Draft Repository")
            .toolbar {
                EditButton()
            }
            .sheet(isPresented: $showingShare) {
                if let exportData,
                   let jsonString = String(data: exportData, encoding: .utf8) {
                    ScrollView {
                        Text(jsonString)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Bulletin Board View
struct BulletinBoardView: View {
    @ObservedObject var store: NoticeStore

    var body: some View {
        NavigationView {
            List(store.bulletinBoard) { notice in
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice.displayTitle)
                        .font(.headline)
                    Text("Created: \(notice.createdDate.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Bulletin Board")
            .onAppear {
                store.fetchBulletinBoard()
            }
        }
    }
}
