//
//  TableType.swift
//  Punktomat
//
//  Created by David Orban on 21.01.26.
//

import Foundation

enum TableType: String, CaseIterable, Identifiable, Codable {
    case standard = "Standard"
    case countdown = "Countdown"

    var id: String { rawValue }
}
