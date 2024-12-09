//
//  ReportsPDFGenerator.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 08/12/24.
//

import PDFKit
import UIKit

struct ReportsPDFGenerator {
    static func generateWeeklyReport(incomes: [IncomeModel], expenses: [ExpenseModel]) -> Data? {
        let pdfData = NSMutableData()
        let pageWidth: CGFloat = 612 // Letter size
        let pageHeight: CGFloat = 792

        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)

        // Add cover page
        addCoverPage(pageWidth: pageWidth, pageHeight: pageHeight)

        // Add incomes page
        addIncomePage(incomes: incomes, pageWidth: pageWidth, pageHeight: pageHeight)

        // Add expenses page
        addExpensePage(expenses: expenses, pageWidth: pageWidth, pageHeight: pageHeight)

        UIGraphicsEndPDFContext()

        return pdfData as Data
    }

    private static func addCoverPage(pageWidth: CGFloat, pageHeight: CGFloat) {
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGreen.cgColor) // primaryGreen color
        context?.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        // App Icon
        if let appIcon = UIImage(named: "AppUtilityIcon") {
            let iconSize: CGFloat = 100
            let iconRect = CGRect(x: (pageWidth - iconSize) / 2, y: 100, width: iconSize, height: iconSize)
            appIcon.draw(in: iconRect)
        }
        
        // Title
        let title = "Weekly Financial Report"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.white
        ]

        title.draw(in: CGRect(x: 0, y: 300, width: pageWidth, height: 50), withAttributes: attributes)
    }

    private static func addIncomePage(incomes: [IncomeModel], pageWidth: CGFloat, pageHeight: CGFloat) {
        UIGraphicsBeginPDFPage()
        drawHeader(title: "Income Overview", yPosition: 20, pageWidth: pageWidth)

        // Table
        drawTable(
            title: "Income Breakdown",
            data: incomes.map { ($0.incomeDescription, String(format: "$%.2f", $0.amount)) },
            startY: 60,
            pageWidth: pageWidth
        )
    }

    private static func addExpensePage(expenses: [ExpenseModel], pageWidth: CGFloat, pageHeight: CGFloat) {
        UIGraphicsBeginPDFPage()
        drawHeader(title: "Expense Overview", yPosition: 20, pageWidth: pageWidth)

        // Table
        drawTable(
            title: "Expense Breakdown",
            data: expenses.map { ($0.expenseDescription, String(format: "$%.2f", $0.amount)) },
            startY: 60,
            pageWidth: pageWidth
        )
    }

    private static func drawHeader(title: String, yPosition: CGFloat, pageWidth: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
    }

    private static func drawTable(title: String, data: [(String, String)], startY: CGFloat, pageWidth: CGFloat) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: 20, y: startY), withAttributes: titleAttributes)

        let rowHeight: CGFloat = 25
        let startX: CGFloat = 20
        let columnWidth: CGFloat = (pageWidth - 40) / 2

        var yOffset = startY + 30

        for (key, value) in data {
            key.draw(in: CGRect(x: startX, y: yOffset, width: columnWidth, height: rowHeight), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ])

            value.draw(in: CGRect(x: startX + columnWidth, y: yOffset, width: columnWidth, height: rowHeight), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ])

            yOffset += rowHeight
        }
    }
}
