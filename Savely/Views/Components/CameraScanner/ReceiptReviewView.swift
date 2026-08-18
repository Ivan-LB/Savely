//
//  ReceiptReviewView.swift
//  Savely
//
//  The "we read this — is it right?" screen. Everything on it is editable:
//  the amount (keypad), the other amounts read from the receipt (chips),
//  the merchant, the date and the category chip. Nothing is saved until
//  the user taps Save; a failed save keeps the screen open and says why.
//

import SwiftUI

struct ReceiptReviewView: View {
    @Bindable var model: ReceiptScanModel

    private var review: Binding<ReceiptReview>? {
        Binding($model.review)
    }

    var body: some View {
        if let review {
            content(review)
        }
    }

    @ViewBuilder
    private func content(_ review: Binding<ReceiptReview>) -> some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    lead(review.wrappedValue)
                    amount(review)
                    if !review.wrappedValue.alternatives.isEmpty {
                        alternatives(review.wrappedValue)
                    }
                    merchantField(review)
                    dateRow(review)
                    categoryChips(review)
                    if let message = model.saveErrorMessage {
                        Text(message)
                            .warmFont(13, weight: .medium)
                            .foregroundStyle(Color.warmClay)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24).padding(.top, 12)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                    #if DEBUG
                    debugExport
                    #endif
                    Spacer(minLength: 12)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            WarmKeypad(amountStr: review.amountText)
        }
        .background(Color.warmBg)
    }

    // MARK: - Pieces

    /// Retake · title · Save on one row; at accessibility sizes the title
    /// drops under the buttons instead of truncating.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                retakeButton
                Spacer()
                title
                Spacer()
                saveButton
            }
            VStack(spacing: 6) {
                HStack {
                    retakeButton
                    Spacer()
                    saveButton
                }
                title
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
    }

    private var title: some View {
        Text(Strings.Camera.reviewTitle)
            .warmFont(18, weight: .regular, design: .serif)
            .foregroundStyle(Color.warmInk)
            .accessibilityAddTraits(.isHeader)
    }

    private var retakeButton: some View {
        Button(action: { model.retake() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").warmFont(13, weight: .semibold)
                Text(Strings.Camera.retakeLabel).warmFont(13, weight: .semibold)
            }
            .foregroundStyle(Color.warmInkSoft)
            .tappable44()
        }
    }

    private var saveButton: some View {
        Button(action: { model.save() }) {
            Text(Strings.Camera.saveExpenseLabel)
                .warmFont(13, weight: .semibold)
                .foregroundStyle(Color.warmOnGreen)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(Color.warmGreenFill)
                .clipShape(Capsule())
        }
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.4)
    }

    private var canSave: Bool { (model.review?.amountValue ?? 0) > 0 }

    private func lead(_ review: ReceiptReview) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(uiImage: review.image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.warmLine, lineWidth: 1))
                .accessibilityLabel(Strings.Camera.receiptThumbnailLabel)
            VStack(alignment: .leading, spacing: 4) {
                Text(leadCopy(review))
                    .warmFont(15, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Strings.Camera.privacyNote)
                    .warmFont(11)
                    .foregroundStyle(Color.warmInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private func leadCopy(_ review: ReceiptReview) -> String {
        switch review.confidence {
        case .high, .medium: return Strings.Camera.reviewLeadRead
        case .low: return Strings.Camera.reviewLeadUnsure
        case .none: return review.amountValue == nil ? Strings.Camera.reviewLeadNone : Strings.Camera.reviewLeadUnsure
        }
    }

    private func amount(_ review: Binding<ReceiptReview>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("−$")
                .warmFont(28, weight: .regular, design: .serif).foregroundStyle(Color.warmInkMuted)
            Text(formatKeypadAmount(review.wrappedValue.amountText))
                .warmFont(60, weight: .regular, design: .serif).foregroundStyle(Color.warmInk)
                .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
            if let currency = review.wrappedValue.currencyHint {
                Text(currency)
                    .warmFont(12, weight: .semibold)
                    .foregroundStyle(Color.warmInkMuted)
                    .padding(.leading, 4)
            }
        }
        .padding(.top, 14)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Strings.Camera.amountAccessibilityLabel))
        .accessibilityValue(Text(review.wrappedValue.amountText))
    }

    private func alternatives(_ review: ReceiptReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Camera.alternativesLabel)
                .warmFont(11, weight: .semibold)
                .foregroundStyle(Color.warmInkMuted)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(review.alternatives, id: \.self) { value in
                        Button(action: { model.pickAlternative(value) }) {
                            Text(formatKeypadAmount(ReceiptScanModel.keypadString(for: value)))
                                .warmFont(13, weight: .semibold)
                                .monospacedDigit()
                                .foregroundStyle(Color.warmInk)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.warmSurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                                .tappable44()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 14)
    }

    private func merchantField(_ review: Binding<ReceiptReview>) -> some View {
        TextField(Strings.Camera.merchantPlaceholder, text: review.merchant)
            .warmFont(13).foregroundStyle(Color.warmInk)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.warmSurface).clipShape(Capsule())
            .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
            .padding(.horizontal, 48).padding(.top, 16)
    }

    private func dateRow(_ review: Binding<ReceiptReview>) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Camera.dateLabel)
                    .warmFont(13, weight: .semibold)
                    .foregroundStyle(Color.warmInk)
                Text(review.wrappedValue.dateWasRead ? Strings.Camera.dateFromReceiptNote : Strings.Camera.dateTodayNote)
                    .warmFont(11)
                    .foregroundStyle(Color.warmInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            DatePicker("", selection: review.date, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .tint(Color.warmGreen)
                .accessibilityLabel(Strings.Camera.dateLabel)
        }
        .padding(.horizontal, 20).padding(.top, 14)
    }

    private func categoryChips(_ review: Binding<ReceiptReview>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExpenseCategory.allCases) { cat in
                    let isOn = review.wrappedValue.category == cat
                    let fg = cat == .other ? Color.warmInkSoft : cat.tileColor
                    Button(action: { review.wrappedValue.category = cat }) {
                        Text(cat.label)
                            .warmFont(13, weight: .semibold)
                            .foregroundStyle(isOn ? fg : Color.warmInkSoft)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isOn ? cat.tileBackground : Color.clear)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isOn ? cat.tileBackground : Color.warmLine, lineWidth: 1))
                            .tappable44()
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 14)
    }

    #if DEBUG
    /// Debug builds only: share what OCR read as a JSON fixture. The file is
    /// written when the button is tapped, not on every render.
    private var debugExport: some View {
        DebugDumpButton(model: model)
    }
    #endif
}

#if DEBUG
private struct DebugDumpButton: View {
    let model: ReceiptScanModel
    @State private var dumpURL: URL?

    var body: some View {
        Group {
            if let dumpURL {
                ShareLink(item: dumpURL) {
                    Label(Strings.Camera.exportDumpLabel, systemImage: "square.and.arrow.up")
                }
            } else {
                Button(action: { dumpURL = model.exportOCRDump() }) {
                    Label(Strings.Camera.exportDumpLabel, systemImage: "doc.text")
                }
            }
        }
        .warmFont(11)
        .foregroundStyle(Color.warmInkMuted)
        .padding(.top, 14)
    }
}
#endif
