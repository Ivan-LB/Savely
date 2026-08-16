//
//  DepositModel.swift
//  Savely
//
//  One row per movement of money into a goal — manual or payday auto-move.
//  `GoalModel.current` stays the running total the UI reads; this is the
//  record of how it got there. Written only through `GoalDeposits.record`.
//

import Foundation
import SwiftData

@Model
class DepositModel {
    @Attribute(.unique) var id: UUID
    /// The goal this deposit went into. A plain UUID rather than a
    /// relationship on purpose: deleting a goal should not cascade-delete
    /// the history, and the ledger must not keep a deleted goal alive.
    var goalID: UUID
    var amount: Double
    var date: Date
    var note: String?
    /// `DepositSource.rawValue` — "manual" or "auto-move".
    var source: String

    init(goalID: UUID, amount: Double, date: Date = Date(), note: String? = nil, source: DepositSource) {
        self.id = UUID()
        self.goalID = goalID
        self.amount = amount
        self.date = date
        self.note = note
        self.source = source.rawValue
    }
}

enum DepositSource: String {
    case manual = "manual"
    case autoMove = "auto-move"
}
