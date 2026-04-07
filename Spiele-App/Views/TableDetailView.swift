//
//  TableDetailView.swift
//  Spiele-App
//
//  Created by David Orban on 21.01.26.
//


import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif

struct TableDetailView: View {
    let table: Table
    var onDuplicate: (() -> Void)? = nil

    @AppStorage("useNumberPad") private var useNumberPad: Bool = true

    private var storageKey: String {
        "columns_\(table.id.uuidString)"
    }

    @State private var columns: [ColumnData] = []
    @State private var newValue: String = ""
    @State private var selectedColumnIndex: Int = 0
    @State private var remainingValues: [Double] = []
    @State private var sortAscending: Bool = false
    @State private var previousRanking: [Int] = []
    @State private var items: [(index: Int, name: String, value: Double)] = []
    @State private var trends: [RankingTrend] = []

    private func sum(for column: ColumnData) -> Double {
        column.values.reduce(0, +)
    }

    private func columnData() -> [(index: Int, name: String, value: Double)] {
        columns.enumerated().map { index, column in
            if table.type == .countdown {
                let remaining = remainingValues.indices.contains(index)
                    ? remainingValues[index]
                    : table.startValue
                return (index, column.name, remaining)
            } else {
                return (index, column.name, sum(for: column))
            }
        }
    }

    private func sortedColumnData() -> [(index: Int, name: String, value: Double)] {
        let data = columnData()
        return data.sorted {
            sortAscending ? $0.value < $1.value : $0.value > $1.value
        }
    }
    

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack {
                    VStack(spacing: 16) {
                    if columns.isEmpty {
                        ProgressView()
                    } else {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach($columns.indices, id: \.self) { index in
                                    if table.type == .countdown {
                                        VStack(alignment: .leading, spacing: 8) {
                                            TextField("Spaltenname", text: $columns[index].name)
                                                .font(.headline)
                                                .textFieldStyle(.roundedBorder)

                                            ScrollView {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(columns[index].values.indices, id: \.self) { valueIndex in
                                                        HStack {
                                                            Text("\(columns[index].values[valueIndex], format: .number)")
                                                            Spacer()
                                                            Button(action: {
                                                                columns[index].values.remove(at: valueIndex)
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

                                            Text("Verbleibend: \(remainingValues.indices.contains(index) ? remainingValues[index] : table.startValue, format: .number)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .frame(minWidth: 150)
                                        .background(.thinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .id(index)
                                    } else {
                                        ColumnView(column: $columns[index])
                                            .id(index)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical)

                        if !columns.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Übersicht")
                                        .font(.headline)

                                    Spacer()

                                    Button {
                                        sortAscending.toggle()
                                    } label: {
                                        Image(systemName: "arrow.up.arrow.down")
                                    }
                                }

                                ForEach(items.indices, id: \.self) { rank in
                                    RankingRowView(
                                        rank: rank,
                                        item: items[rank],
                                        trend: trends.indices.contains(rank) ? trends[rank] : .none,
                                        onTap: {
                                            withAnimation {
                                                proxy.scrollTo(items[rank].index, anchor: .center)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }

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
                                    .keyboardType(useNumberPad ? .numberPad : .numbersAndPunctuation)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .onSubmit {
                                        addValueToSelectedColumn()
                                    }
                                
                                Button("Hinzufügen") {
                                    addValueToSelectedColumn()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .id("inputField")
                    }
                    }
                    .padding(.top)
                }
                // Swipe action for duplicating the table
                .swipeActions(edge: .trailing) {
                    Button(action: {
                        onDuplicate?()
                    }) {
                        Label("Duplizieren", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
            .padding(.bottom)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                loadColumns()
                updateRanking(resetTrends: true)
            }
            .onChange(of: columns) {
                saveColumns(columns)
            }
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect != nil {
                    withAnimation {
                        proxy.scrollTo("inputField", anchor: .center)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: columns) {
                updateRanking(resetTrends: false)
            }
            .onChange(of: sortAscending) {
                updateRanking(resetTrends: true)
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

    private func addValueToSelectedColumn() {
        guard !columns.isEmpty else { return }
        guard let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) else { return }

        if table.type == .countdown {
            guard remainingValues.indices.contains(selectedColumnIndex) else { return }

            let newRemaining = max(remainingValues[selectedColumnIndex] - value, 0)
            columns[selectedColumnIndex].values.append(value)
            remainingValues[selectedColumnIndex] = newRemaining
        } else {
            columns[selectedColumnIndex].values.append(value)
        }

        newValue = ""
        advanceToNextColumn()
        hapticSubmit()
    }

    private func advanceToNextColumn() {
        guard !columns.isEmpty else { return }
        selectedColumnIndex = (selectedColumnIndex + 1) % columns.count
    }

    private func updateRanking(resetTrends: Bool) {
        let sortedItems = sortedColumnData()
        let currentRanking = sortedItems.map(\.index)

        if resetTrends || previousRanking.isEmpty {
            trends = sortedItems.map { _ in .none }
        } else {
            trends = sortedItems.map { item in
                trend(for: item.index, currentRanking: currentRanking)
            }
        }

        items = sortedItems
        previousRanking = currentRanking
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
            presentShareSheet(for: url)
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

            presentShareSheet(for: url)
        } catch {
            print("PDF Export fehlgeschlagen:", error)
        }
    }

    private func presentShareSheet(for url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = rootViewController.view
            popoverPresentationController.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverPresentationController.permittedArrowDirections = []
        }

        rootViewController.present(activityViewController, animated: true)
    }
    
    
    private func trend(for index: Int, currentRanking: [Int]) -> RankingTrend {
        guard let previousPosition = previousRanking.firstIndex(of: index),
              let currentPosition = currentRanking.firstIndex(of: index)
        else {
            return .none
        }

        if currentPosition < previousPosition {
            return .up
        } else if currentPosition > previousPosition {
            return .down
        } else {
            return .none
        }
    }
    
    // MARK: - Haptic Feedback
    private func hapticSubmit() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

enum RankingTrend {
    case up
    case down
    case none

    var icon: String? {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .none: return nil
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .none: return .clear
        }
    }
}

struct RankingRowView: View {
    let rank: Int
    let item: (index: Int, name: String, value: Double)
    let trend: RankingTrend
    let onTap: () -> Void

    var body: some View {
        HStack {
            if let symbolName = placementSymbolName, let symbolColor = placementSymbolColor {
                Image(systemName: symbolName)
                    .foregroundStyle(symbolColor)
            }

            if let icon = trend.icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }

            Text(item.name)
                .fontWeight(rank < 3 ? .bold : .regular)

            Spacer()

            Text(item.value, format: .number)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
    }

    private var placementSymbolName: String? {
        switch rank {
        case 0: return "medal.fill"
        case 1: return "medal"
        case 2: return "rosette"
        default: return nil
        }
    }

    private var placementSymbolColor: Color? {
        switch rank {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .brown
        default: return nil
        }
    }

    private var backgroundView: some View {
        Color.clear
    }
}

#Preview {
    ContentView()
}
