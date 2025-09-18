//
//  NoticeDetailView.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 17/09/2025.
//

import SwiftUI

struct NoticeDetailView: View {
    let notice: Notice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(notice.displayTitle)
                    .font(.title)
                    .bold()
                
                Text("Created: \(notice.createdDate.formatted())")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()
                
                ForEach(notice.fields) { field in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(field.key)
                            .font(.headline)
                        Text(field.value.isEmpty ? "—" : field.value)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                    }
                    .padding(.bottom, 8 )
                }
                
                
                HStack(spacing: 12) {
                    Button("GONG This") {
                        //showGongForm = true//
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("View Attachments") {
                        //add redirect to attachments//
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Notice Details")

    }
}

#Preview {
    NoticeDetailView(notice: .mock)
}
