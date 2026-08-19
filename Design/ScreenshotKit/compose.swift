#!/usr/bin/env swift
//
//  compose.swift — Savely App Store screenshot composer
//
//  Renders the eight 6.9" pages (1320×2868) of docs/plans/app-store-screenshots.md
//  from raw Simulator captures, using the real system fonts (New York / SF Pro)
//  through SwiftUI's ImageRenderer on macOS. Nothing is embedded, nothing is
//  redrawn inside the captures — the screenshot is placed, scaled and clipped.
//
//      swift Design/ScreenshotKit/compose.swift <captures-dir> <out-dir>
//
//  Captures expected in <captures-dir> (from StoreScreenshotTourUITests):
//      01-goal-on-track.png 02-privacy.png 03-payday.png 04-expense.png
//      05-receipt-review.png 06-month-trend.png 07-goal-behind.png 08-home-dark.png
//  Output: savely-en-US-01-goal.png … savely-en-US-08-night.png (RGBA; flatten to
//  RGB before upload — see Design/ScreenshotKit/README.md).
//

import AppKit
import SwiftUI

// MARK: - Tokens (DESIGN.md)

struct Theme {
    let bg, ink, inkSoft, green, line, bezel, bezelLine: Color
    let leafPrimary, leafSecondary, seed: Color
    static let light = Theme(
        bg: hex(0xF6F4EE), ink: hex(0x1A1A17), inkSoft: hex(0x55524C), green: hex(0x2F6B4A),
        line: Color(red: 30 / 255, green: 25 / 255, blue: 15 / 255).opacity(0.08),
        bezel: hex(0x1A1A17), bezelLine: .clear,
        leafPrimary: hex(0x2F6B4A), leafSecondary: hex(0x37795A), seed: hex(0xA8741C)
    )
    static let dark = Theme(
        bg: hex(0x161512), ink: hex(0xF2EFE7), inkSoft: hex(0xC6C1B5), green: hex(0x78B58F),
        line: Color(red: 242 / 255, green: 239 / 255, blue: 231 / 255).opacity(0.10),
        bezel: hex(0x262420), bezelLine: Color(red: 242 / 255, green: 239 / 255, blue: 231 / 255).opacity(0.10),
        leafPrimary: hex(0x78B58F), leafSecondary: hex(0x5D9C7C), seed: hex(0xDEA64A)
    )
    static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

// MARK: - Frames (copy lives here on purpose: one file, one source of truth)

struct Frame {
    let n: Int, slug: String, capture: String, kicker: String, headline: String, sub: String
    let stage: Int   // sprout growth stage 1…8
    let dark: Bool
}

let frames: [Frame] = [
    Frame(n: 1, slug: "goal", capture: "01-goal-on-track", kicker: "Savings",
          headline: "Your goal.\nA real pace.",
          sub: "On track or behind — from what you actually put in.", stage: 1, dark: false),
    Frame(n: 2, slug: "privacy", capture: "02-privacy", kicker: "Your data",
          headline: "No account.\nNo cloud.",
          sub: "Your money data lives on your iPhone and never leaves it.", stage: 2, dark: false),
    Frame(n: 3, slug: "payday", capture: "03-payday", kicker: "Payday",
          headline: "Save before\nyou spend.",
          sub: "Log your pay, tap Yes, and part of it goes to your goal.", stage: 3, dark: false),
    Frame(n: 4, slug: "expense", capture: "04-expense", kicker: "Everyday money",
          headline: "Log it in\nseconds.",
          sub: "Amount, a category, done. The rest is optional.", stage: 4, dark: false),
    Frame(n: 5, slug: "receipt", capture: "05-receipt-review", kicker: "Receipts",
          headline: "Scan it.\nIt stays here.",
          sub: "Total, merchant, date — read on your iPhone, never uploaded.", stage: 5, dark: false),
    Frame(n: 6, slug: "month", capture: "06-month-trend", kicker: "The month",
          headline: "Bad months\ncount too.",
          sub: "Real trends, month over month. Drops included.", stage: 6, dark: false),
    Frame(n: 7, slug: "pace", capture: "07-goal-behind", kicker: "The pace",
          headline: "The date\nis honest.",
          sub: "The ETA comes from real deposits. Behind is shown, not hidden.", stage: 7, dark: false),
    Frame(n: 8, slug: "night", capture: "08-home-dark", kicker: "At night",
          headline: "The notebook,\nunder a lamp.",
          sub: "Dark mode keeps the warmth. Same calm.", stage: 8, dark: true),
]

// MARK: - Sprout (SproutMark.swift geometry, 120-unit space)

func pt(_ x: CGFloat, _ y: CGFloat, _ r: CGRect) -> CGPoint {
    CGPoint(x: r.minX + x / 120 * r.width, y: r.minY + y / 120 * r.height)
}
struct StemShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: pt(60, 87, r))
        p.addCurve(to: pt(60, 56, r), control1: pt(52, 76, r), control2: pt(68, 68, r)); return p
    }
}
struct SeedShape: Shape {
    func path(in r: CGRect) -> Path {
        let c = pt(60, 92, r); let rad = 9 / 120 * r.width
        return Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2))
    }
}
struct LeafShape: Shape {
    let left: Bool
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: pt(60, 56, r))
        if left {
            p.addCurve(to: pt(36, 26, r), control1: pt(42, 54, r), control2: pt(34, 40, r))
            p.addCurve(to: pt(60, 56, r), control1: pt(52, 28, r), control2: pt(60, 42, r))
        } else {
            p.addCurve(to: pt(82, 28, r), control1: pt(74, 52, r), control2: pt(82, 40, r))
            p.addCurve(to: pt(60, 56, r), control1: pt(68, 30, r), control2: pt(60, 42, r))
        }
        p.closeSubpath(); return p
    }
}

/// Growth stages: 1 seed · 2 stem 35 % · 3 stem 100 % · 4 + left leaf 45 % ·
/// 5 left leaf 100 % · 6 + right leaf 45 % · 7 full · 8 full (dark tokens).
struct Sprout: View {
    let stage: Int, theme: Theme, size: CGFloat
    var stem: CGFloat { stage <= 1 ? 0 : (stage == 2 ? 0.35 : 1) }
    var leftLeaf: CGFloat { stage <= 3 ? 0 : (stage == 4 ? 0.45 : 1) }
    var rightLeaf: CGFloat { stage <= 5 ? 0 : (stage == 6 ? 0.45 : 1) }
    var body: some View {
        let tip = UnitPoint(x: 60 / 120, y: 56 / 120)
        ZStack {
            StemShape().trim(from: 0, to: stem)
                .stroke(theme.leafPrimary, style: StrokeStyle(lineWidth: size * 5.5 / 120, lineCap: .round))
            SeedShape().fill(theme.seed)
            LeafShape(left: true).fill(theme.leafPrimary).scaleEffect(leftLeaf, anchor: tip)
            LeafShape(left: false).fill(theme.leafSecondary).scaleEffect(rightLeaf, anchor: tip)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Page

let W: CGFloat = 1320, H: CGFloat = 2868
let margin: CGFloat = 96
let ruleY: CGFloat = 192
let sproutSize: CGFloat = 240
let bezelWidth: CGFloat = 1002, bezelInset: CGFloat = 26, bezelTop: CGFloat = 980
let screenWidth: CGFloat = bezelWidth - 2 * bezelInset            // 950
let screenHeight: CGFloat = screenWidth * H / W                   // 2064
let bezelRadius: CGFloat = 160, screenRadius: CGFloat = 134

struct Page: View {
    let frame: Frame
    let shot: NSImage
    var theme: Theme { frame.dark ? .dark : .light }

    var body: some View {
        ZStack(alignment: .topLeading) {
            theme.bg

            // Header rule (full bleed) — the one "ruled paper" cue.
            Rectangle().fill(theme.line).frame(width: W, height: 3).offset(y: ruleY)

            // Kicker — the app's own tracked label, in green as ink.
            Text(frame.kicker.uppercased())
                .font(.system(size: 36, weight: .semibold))
                .tracking(3.6)
                .foregroundStyle(theme.green)
                .offset(x: margin, y: 118)

            // Growth mark: seed tangent to the rule, right-aligned to the margin.
            Sprout(stage: frame.stage, theme: theme, size: sproutSize)
                .offset(x: W - margin - sproutSize, y: ruleY - sproutSize * 101 / 120 + 1.5)

            // Headline + sub
            VStack(alignment: .leading, spacing: 28) {
                Text(frame.headline)
                    .font(.system(size: 136, weight: .regular, design: .serif))
                    .foregroundStyle(theme.ink)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 1128, alignment: .leading)
                Text(frame.sub)
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(theme.inkSoft)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 980, alignment: .leading)
            }
            .offset(x: margin, y: 236)

            // The photo: flat, untilted, tucked under the page edge.
            device
                .offset(x: margin, y: bezelTop)
        }
        .frame(width: W, height: H)
        .clipped()
    }

    var device: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: bezelRadius, style: .continuous)
                .fill(theme.bezel)
                .overlay(RoundedRectangle(cornerRadius: bezelRadius, style: .continuous).stroke(theme.bezelLine, lineWidth: 3))
            Image(nsImage: shot)
                .resizable()
                .interpolation(.high)
                .frame(width: screenWidth, height: screenHeight)
                .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
                .offset(y: bezelInset)
            // Dynamic Island as part of the bezel silhouette.
            Capsule().fill(theme.bezel).frame(width: 270, height: 80).offset(y: bezelInset + 18)
        }
        .frame(width: bezelWidth, height: screenHeight + 2 * bezelInset + 200, alignment: .top)
    }
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: compose.swift <captures-dir> <out-dir>\n".utf8))
    exit(2)
}
let capturesDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

MainActor.assumeIsolated {
    for frame in frames {
        let shotURL = capturesDir.appendingPathComponent(frame.capture + ".png")
        guard let shot = NSImage(contentsOf: shotURL) else {
            print("!! missing capture \(shotURL.path)"); continue
        }
        let renderer = ImageRenderer(content: Page(frame: frame, shot: shot))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: W, height: H)
        guard let cg = renderer.cgImage else { print("!! render failed \(frame.n)"); continue }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let png = rep.representation(using: .png, properties: [:]) else { continue }
        let name = String(format: "savely-en-US-%02d-%@.png", frame.n, frame.slug)
        let out = outDir.appendingPathComponent(name)
        do { try png.write(to: out); print("wrote \(name) \(cg.width)x\(cg.height)") } catch { print("!! \(error)") }
    }
}
