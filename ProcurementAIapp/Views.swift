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
// Updated NoticeFormView with inline validation only, no JSON preview

struct NoticeFormView: View {
    @ObservedObject var store: NoticeStore
    var noticeType: NoticeType
    @State private var fields: [FormField]

    @State private var isSaving = false
    @State private var showSavedToast = false
    @State private var showValidationError = false

    init(store: NoticeStore, noticeType: NoticeType) {
        self.store = store
        self.noticeType = noticeType
        _fields = State(initialValue: noticeType.requiredFields)
    }

    var body: some View {
        Form {
            ForEach($fields) { $field in
                VStack(alignment: .leading, spacing: 6) {
                    TextField(field.key, text: $field.value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let tip = field.tooltip, !tip.isEmpty {
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 2)
            }

            if showValidationError {
                Text("⚠️ Please fill in at least one field before saving.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: saveNotice) {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Save Notice")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(noticeType.rawValue)
        .overlay(alignment: .top) {
            if showSavedToast {
                Text("✅ Notice saved")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    private func saveNotice() {
        let hasContent = fields.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard hasContent else {
            showValidationError = true
            return
        }

        showValidationError = false
        isSaving = true
        let newNotice = Notice(type: noticeType, fields: fields)
        store.saveDraft(newNotice)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isSaving = false
            withAnimation { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation { showSavedToast = false }
            }
            fields = noticeType.requiredFields
        }
    }
}

// MARK: - Repository View
struct RepositoryView: View {
    @ObservedObject var store: NoticeStore
    @State private var showingShare = false
    @State private var exportData: Data?
    @State private var showingPostConfirm = false
    @State private var noticeToPost: Notice?
    @State private var showingPostSuccess = false

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
                                noticeToPost = notice
                                showingPostConfirm = true
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
            .alert("Post Notice", isPresented: $showingPostConfirm, presenting: noticeToPost) { notice in
                Button("Cancel", role: .cancel) {}
                Button("Post", role: .destructive) {
                    store.postNotice(notice)
                    if let index = store.notices.firstIndex(where: { $0.id == notice.id }) {
                        store.notices.remove(at: index)
                    }
                    showingPostSuccess = true
                }
            } message: { notice in
                Text("Are you sure you want to post \(notice.displayTitle)?")
            }
            .alert("✅ Posted!", isPresented: $showingPostSuccess) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

// MARK: - Bulletin Board View
struct BulletinBoardView: View {
    @ObservedObject var store: NoticeStore

    var body: some View {
        NavigationView {
            List(store.bulletinBoard, id: \.id) { notice in
                NavigationLink(destination: NoticeDetailView(notice: notice)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(notice.displayTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Label {
                            Text(notice.createdDate.formatted())
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(8)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.vertical, 4)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable { store.fetchBulletinBoard() }
            .onAppear { store.fetchBulletinBoard() }
            .navigationTitle("Bulletin Board")
        }
    }
}
// Account View
struct AccountView: View {
    @ObservedObject var store: NoticeStore
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
