//
//  ColumnView.swift
//  Spiele-App
//
//  Created by David Orban on 21.01.26.
//

import Foundation
import SwiftUI


struct ColumnView: View {
    @Binding var column: ColumnData

    var body: some View {
        let sum = column.values.reduce(0, +)

        VStack(alignment: .leading, spacing: 8) {
            TextField("Spaltenname", text: $column.name)
                .font(.headline)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(column.values.indices, id: \.self) { index in
                        HStack {
                            Text("\(column.values[index], format: .number)")
                            Spacer()
                            Button(action: {
                                column.values.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .frame(height: 200)

            Text("Summe: \(sum, format: .number)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 150)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}



#Preview {
    ContentView()
}
