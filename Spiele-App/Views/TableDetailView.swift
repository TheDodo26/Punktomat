//
//  TableDetailView.swift
//  Spiele-App
//
//  Created by David Orban on 21.01.26.
//

import SwiftUI

struct TableDetailView: View {
    let table: Table

    // One storage key per table
    private var storageKey: String {
        "columns_\(table.id.uuidString)"
    }

    // Each column has a name and its own values
    struct ColumnData: Codable, Identifiable, Equatable {
        var id = UUID()
        var name: String
        var values: [Double]
    }

    @State private var columns: [ColumnData] = []
    @State private var newValue: String = ""
    @State private var selectedColumnIndex: Int = 0
    @State private var remainingValues: [Double] = []
    @State private var keyboardHeight: CGFloat = 0
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    init(table: Table) {
        self.table = table
        if table.type == .countdown {
            _remainingValues = State(initialValue: [])
        } else {
            _remainingValues = State(initialValue: [])
        }
    }

    private func sum(for column: ColumnData) -> Double {
        column.values.reduce(0, +)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if columns.isEmpty {
                        ProgressView()
                    } else {
                        // Horizontal ScrollView for columns
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach($columns.indices, id: \.self) { index in
                                    if table.type == .countdown {
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Editable column name
                                            TextField("Spaltenname", text: $columns[index].name)
                                                .font(.headline)
                                                .textFieldStyle(.roundedBorder)
                                            
                                            // ScrollView for values with delete button
                                            ScrollView {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(columns[index].values.indices, id: \.self) { valueIndex in
                                                        HStack {
                                                            Text("\(columns[index].values[valueIndex], format: .number)")
                                                            Spacer()
                                                            Button(action: {
                                                                columns[index].values.remove(at: valueIndex)
                                                                // Update remaining value after deletion
                                                                let sumValues = columns[index].values.reduce(0, +)
                                                                remainingValues[index] = max(table.startValue - sumValues, 0)
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .foregroundStyle(.red)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(height: 200)
                                            
                                            // Remaining value for this column
                                            Text("Verbleibend: \(remainingValues.indices.contains(index) ? remainingValues[index] : table.startValue, format: .number)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .frame(minWidth: 150)
                                        .background(.thinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        ColumnView(column: $columns[index])
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Input section for adding new values
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Neuen Wert hinzufügen")
                                .font(.headline)
                            
                            Picker(selection: $selectedColumnIndex, label: Text("Spalte")) {
                                ForEach(columns.indices, id: \.self) { index in
                                    Text(columns[index].name).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                TextField("Wert eingeben", text: $newValue)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .onSubmit {
                                        if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                            if table.type == .countdown {
                                                if remainingValues.indices.contains(selectedColumnIndex) {
                                                    let newRemaining = max(remainingValues[selectedColumnIndex] - value, 0)
                                                    if newRemaining >= 0 {
                                                        columns[selectedColumnIndex].values.append(value)
                                                        remainingValues[selectedColumnIndex] = newRemaining
                                                    }
                                                }
                                            } else {
                                                columns[selectedColumnIndex].values.append(value)
                                            }
                                            newValue = ""
                                        }
                                    }
                                
                                Button("Hinzufügen") {
                                    if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                        if table.type == .countdown {
                                            if remainingValues.indices.contains(selectedColumnIndex) {
                                                let newRemaining = max(remainingValues[selectedColumnIndex] - value, 0)
                                                if newRemaining >= 0 {
                                                    columns[selectedColumnIndex].values.append(value)
                                                    remainingValues[selectedColumnIndex] = newRemaining
                                                }
                                            }
                                        } else {
                                            columns[selectedColumnIndex].values.append(value)
                                        }
                                        newValue = ""
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .id("inputField")
                    }
                }
                .padding(.top)
            }
            .padding(.bottom, keyboardHeight)
            .onAppear { loadColumns() }
            .onChange(of: columns) { newColumns in saveColumns(newColumns) }
            .navigationTitle(table.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Als PDF exportieren") {
                            exportPDF()
                        }
                        Button("Als CSV exportieren") {
                            exportCSV()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let exportURL {
                    ShareLink(item: exportURL)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                    withAnimation {
                        proxy.scrollTo("inputField", anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
    }


    private func loadColumns() {
        if
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([ColumnData].self, from: data)
        {
            columns = decoded
            selectedColumnIndex = 0
            if table.type == .countdown {
                remainingValues = columns.map { _ in table.startValue }
                for (index, column) in columns.enumerated() {
                    let sumValues = column.values.reduce(0, +)
                    remainingValues[index] = max(table.startValue - sumValues, 0)
                }
            }
        } else {
            // Initial setup with default column names
            columns = (1...table.columns).map {
                ColumnData(name: "Spalte \($0)", values: [])
            }
            selectedColumnIndex = 0
            if table.type == .countdown {
                remainingValues = Array(repeating: table.startValue, count: table.columns)
            }
        }
    }

    private func saveColumns(_ columns: [ColumnData]) {
        if let data = try? JSONEncoder().encode(columns) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

// MARK: - Export

    private func exportCSV() {
        var csv = "Spalte,Wert\n"

        for column in columns {
            for value in column.values {
                csv.append("\(column.name),\(value)\n")
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(table.name).csv")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showExportSheet = true
        } catch {
            print("CSV Export fehlgeschlagen:", error)
        }
    }

    private func exportPDF() {
        let pageSize = CGSize(width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(table.name).pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()

                var yOffset: CGFloat = 20
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20)
                ]

                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]

                let title = "\(table.name)\n\n"
                title.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: titleAttributes)
                yOffset += 40

                for column in columns {
                    let header = "\(column.name)\n"
                    header.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: titleAttributes)
                    yOffset += 24

                    for value in column.values {
                        let line = "• \(value)\n"
                        line.draw(
                            in: CGRect(x: 30, y: yOffset, width: pageSize.width - 60, height: 20),
                            withAttributes: textAttributes
                        )
                        yOffset += 18

                        if yOffset > pageSize.height - 40 {
                            context.beginPage()
                            yOffset = 20
                        }
                    }

                    yOffset += 12
                }
            }

            exportURL = url
            showExportSheet = true
        } catch {
            print("PDF Export fehlgeschlagen:", error)
        }
    }
}

#Preview {
    ContentView()
}
