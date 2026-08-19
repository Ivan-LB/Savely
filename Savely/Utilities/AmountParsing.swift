//
//  AmountParsing.swift
//  Savely
//
//  One shared parser for every user-entered money amount.
//

import Foundation

/// Parses a user-entered amount into a positive `Double`.
///
/// Both separators are accepted regardless of the device locale: the in-app
/// keypad hardcodes `"."`, while the system decimal pad shows `","` in
/// comma-decimal locales (es-ES, fr-FR, de-DE…). es-MX uses `"."`, so it was
/// never the broken case — the comma locales were.
///
/// A comma is only ever read as a *decimal* separator, never as a thousands
/// separator. Anything ambiguous (`"1,234.56"`, `"12,34,56"`) is rejected
/// rather than guessed at — silently misreading an amount by a factor of 100
/// is worse than making the user retype it.
///
/// - Returns: the parsed amount, or `nil` when the input is empty, is not a
///   number, or is not greater than zero.
func parseAmount(_ raw: String) -> Double? {
    guard let value = decimalValue(of: raw), value > 0 else { return nil }
    return value
}

private func decimalValue(of raw: String) -> Double? {
    if let value = Double(raw) { return value }
    // Retry as comma-decimal — but only when that reading is unambiguous.
    guard raw.filter({ $0 == "," }).count == 1, !raw.contains(".") else { return nil }
    return Double(raw.replacingOccurrences(of: ",", with: "."))
}
