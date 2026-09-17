import Foundation
import UIKit

/// Выбранный пользователем период e-statement. Даты нормализуются до полных
/// календарных суток, поэтому операции в конце последнего дня не теряются.
struct EStatementPeriod: Hashable {
    let startDate: Date
    let endDate: Date

    var displayTitle: String {
        "\(Self.displayFormatter.string(from: startDate)) - \(Self.displayFormatter.string(from: endDate))"
    }

    var fileToken: String {
        "\(Self.fileFormatter.string(from: startDate))_\(Self.fileFormatter.string(from: endDate))"
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: startDate)
        let endStart = calendar.startOfDay(for: endDate)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endStart) ?? endDate
        return date >= start && date < endExclusive
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private static let fileFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

/// Нативный A4-генератор e-statement. Документ формируется только из данных
/// текущей AppSession и не содержит отдельных захардкоженных транзакций.
enum EStatementPDFRenderer {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let pageMargin: CGFloat = 36
    private static let rowsPerPage = 12
    private static let lavender = UIColor(red: 0.89, green: 0.87, blue: 0.98, alpha: 1)
    private static let mashreqOrange = UIColor(red: 1, green: 0.32, blue: 0.02, alpha: 1)
    private static let ink = UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1)
    private static let secondaryInk = UIColor(red: 0.36, green: 0.36, blue: 0.38, alpha: 1)

    static func makePDF(
        profile: UserProfile,
        accountBalance: Decimal,
        transactions: [Transaction],
        period: EStatementPeriod
    ) throws -> URL {
        let snapshot = makeSnapshot(
            accountBalance: accountBalance,
            transactions: transactions,
            period: period
        )
        let transactionPageCount = max(1, Int(ceil(Double(snapshot.rows.count) / Double(rowsPerPage))))
        let pageCount = transactionPageCount + 1

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Mashreq NEO e-statement \(period.displayTitle)",
            kCGPDFContextAuthor as String: "Mashreq NEO",
            kCGPDFContextSubject as String: "Current Account e-statement"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            drawSummaryPage(
                context: context.cgContext,
                profile: profile,
                snapshot: snapshot,
                period: period,
                pageNumber: 1,
                pageCount: pageCount
            )

            for pageIndex in 0..<transactionPageCount {
                context.beginPage()
                let lowerBound = pageIndex * rowsPerPage
                let upperBound = min(lowerBound + rowsPerPage, snapshot.rows.count)
                let pageRows = lowerBound < upperBound
                    ? Array(snapshot.rows[lowerBound..<upperBound])
                    : []
                drawTransactionPage(
                    context: context.cgContext,
                    profile: profile,
                    rows: pageRows,
                    snapshot: snapshot,
                    period: period,
                    pageNumber: pageIndex + 2,
                    pageCount: pageCount,
                    isFirstTransactionPage: pageIndex == 0
                )
            }
        }

        guard !pdfData.isEmpty, pdfData.count > 1_000 else {
            throw EStatementPDFError.emptyOutput
        }

        let safeAccount = profile.accountNumber.filter(\.isNumber)
        let fileName = "Mashreq-eStatement-\(safeAccount)-\(period.fileToken).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try pdfData.write(to: url, options: .atomic)

        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? NSNumber,
            size.intValue > 1_000
        else {
            throw EStatementPDFError.emptyOutput
        }

        return url
    }

    private static func makeSnapshot(
        accountBalance: Decimal,
        transactions: [Transaction],
        period: EStatementPeriod
    ) -> StatementSnapshot {
        let posted = transactions
            .filter { !$0.isProcessing }
            .sorted { $0.createdAt < $1.createdAt }
        let baseOpening = accountBalance - posted.reduce(Decimal.zero) { $0 + $1.signedAmount }
        let periodStart = Calendar.current.startOfDay(for: period.startDate)
        let balanceBeforePeriod = posted
            .filter { $0.createdAt < periodStart }
            .reduce(baseOpening) { $0 + $1.signedAmount }

        var runningBalance = balanceBeforePeriod
        let rows = posted.compactMap { transaction -> StatementRow? in
            guard period.contains(transaction.createdAt) else { return nil }
            runningBalance += transaction.signedAmount
            return StatementRow(transaction: transaction, balance: runningBalance)
        }

        return StatementSnapshot(
            openingBalance: balanceBeforePeriod,
            closingBalance: runningBalance,
            rows: rows
        )
    }

    private static func drawSummaryPage(
        context: CGContext,
        profile: UserProfile,
        snapshot: StatementSnapshot,
        period: EStatementPeriod,
        pageNumber: Int,
        pageCount: Int
    ) {
        drawBrandHeader()
        drawVerticalStatementLabel(context: context)

        drawText(
            profile.fullName.uppercased(),
            in: CGRect(x: 38, y: 108, width: 250, height: 18),
            font: boldFont(10),
            color: ink
        )

        drawInfoPanel(
            title: "Consolidated Relationship Statement",
            rows: [
                ("Issue Date", dateFormatter.string(from: .now)),
                ("Statement Period", period.displayTitle),
                ("Account Currency", "AED")
            ],
            frame: CGRect(x: 260, y: 92, width: 300, height: 132)
        )

        drawText(
            "Mashreq NEO is part of Mashreqbank PSC, regulated by the Central Bank of the United Arab Emirates.",
            in: CGRect(x: 272, y: 190, width: 276, height: 27),
            font: regularFont(6.8),
            color: secondaryInk
        )

        drawSectionTitle("Current Account Summary", y: 252)
        let headers = ["Account type", "Account number", "Currency", "Opening balance", "Available balance"]
        let values = [
            "NEO Current Account",
            profile.accountNumber,
            "AED",
            amountText(snapshot.openingBalance),
            amountText(snapshot.closingBalance)
        ]
        let widths: [CGFloat] = [112, 112, 58, 112, 113]
        drawSummaryTable(headers: headers, values: values, widths: widths, y: 282)

        drawText(
            "IBAN: \(profile.iban)",
            in: CGRect(x: 48, y: 346, width: 410, height: 18),
            font: boldFont(8.2),
            color: ink
        )
        drawText(
            "Posted transactions in selected period: \(snapshot.rows.count)",
            in: CGRect(x: 48, y: 370, width: 410, height: 18),
            font: regularFont(8.2),
            color: secondaryInk
        )

        drawDigitalNotice(y: 690)
        drawFooter(pageNumber: pageNumber, pageCount: pageCount)
    }

    private static func drawTransactionPage(
        context: CGContext,
        profile: UserProfile,
        rows: [StatementRow],
        snapshot: StatementSnapshot,
        period: EStatementPeriod,
        pageNumber: Int,
        pageCount: Int,
        isFirstTransactionPage: Bool
    ) {
        drawBrandHeader()
        drawVerticalStatementLabel(context: context)

        drawText(
            profile.fullName.uppercased(),
            in: CGRect(x: 38, y: 88, width: 220, height: 18),
            font: boldFont(9.3),
            color: ink
        )
        drawInfoPanel(
            title: "Current Account Statement",
            rows: [
                ("Account No", "\(profile.accountNumber)  AED"),
                ("IBAN", profile.iban)
            ],
            frame: CGRect(x: 273, y: 66, width: 287, height: 108)
        )

        drawSectionTitle("Statement for Period \(period.displayTitle)", y: 206)
        let columns: [(String, CGFloat)] = [
            ("Date", 58),
            ("Transaction", 170),
            ("Reference no", 90),
            ("Debit", 60),
            ("Credit", 60),
            ("Balance", 85)
        ]
        drawTableHeader(columns: columns, y: 237)

        var y: CGFloat = 266
        if isFirstTransactionPage {
            drawBalanceRow(title: "OPENING BALANCE", value: snapshot.openingBalance, y: y)
            y += 31
        }

        if rows.isEmpty {
            drawText(
                "No posted transactions for this period.",
                in: CGRect(x: 48, y: y + 20, width: 480, height: 24),
                font: regularFont(10),
                color: secondaryInk,
                alignment: .center
            )
        } else {
            for row in rows {
                drawTransactionRow(row, y: y)
                y += 39
            }
        }

        drawBalanceRow(title: "Balance carried forward", value: rows.last?.balance ?? snapshot.openingBalance, y: min(y + 2, 754))
        drawFooter(pageNumber: pageNumber, pageCount: pageCount)
    }

    private static func drawBrandHeader() {
        drawText(
            "mashreq",
            in: CGRect(x: 393, y: 24, width: 118, height: 32),
            font: boldFont(22),
            color: mashreqOrange,
            alignment: .right
        )
        drawText(
            "NEO",
            in: CGRect(x: 443, y: 51, width: 68, height: 20),
            font: regularFont(15),
            color: mashreqOrange,
            alignment: .right
        )
    }

    private static func drawInfoPanel(
        title: String,
        rows: [(String, String)],
        frame: CGRect
    ) {
        lavender.setFill()
        UIRectFill(frame)
        drawText(title, in: CGRect(x: frame.minX + 8, y: frame.minY + 6, width: frame.width - 16, height: 16), font: boldFont(8.2), color: ink)
        drawLine(from: CGPoint(x: frame.minX + 8, y: frame.minY + 25), to: CGPoint(x: frame.maxX - 8, y: frame.minY + 25), color: ink, width: 1)

        var y = frame.minY + 32
        for row in rows {
            drawText(row.0, in: CGRect(x: frame.minX + 8, y: y, width: 98, height: 14), font: boldFont(7.2), color: UIColor.blue)
            drawText(row.1, in: CGRect(x: frame.minX + 108, y: y, width: frame.width - 116, height: 14), font: boldFont(7.2), color: UIColor.blue, alignment: .right)
            y += 23
        }
    }

    private static func drawSectionTitle(_ title: String, y: CGFloat) {
        lavender.setFill()
        UIRectFill(CGRect(x: 47, y: y, width: 511, height: 22))
        drawText(title, in: CGRect(x: 51, y: y + 4, width: 500, height: 15), font: boldFont(7.5), color: ink)
        drawLine(from: CGPoint(x: 47, y: y + 22), to: CGPoint(x: 558, y: y + 22), color: ink, width: 1)
    }

    private static func drawSummaryTable(
        headers: [String],
        values: [String],
        widths: [CGFloat],
        y: CGFloat
    ) {
        var x: CGFloat = 48
        for index in headers.indices {
            drawText(headers[index], in: CGRect(x: x, y: y, width: widths[index] - 4, height: 25), font: boldFont(7), color: ink, alignment: .center)
            drawText(values[index], in: CGRect(x: x, y: y + 31, width: widths[index] - 4, height: 25), font: regularFont(7.2), color: ink, alignment: .center)
            x += widths[index]
        }
        drawLine(from: CGPoint(x: 47, y: y + 58), to: CGPoint(x: 558, y: y + 58), color: ink, width: 0.8)
    }

    private static func drawTableHeader(columns: [(String, CGFloat)], y: CGFloat) {
        var x: CGFloat = 47
        for column in columns {
            drawText(column.0, in: CGRect(x: x + 2, y: y, width: column.1 - 4, height: 20), font: boldFont(7.2), color: ink, alignment: column.0 == "Transaction" ? .left : .right)
            x += column.1
        }
        drawLine(from: CGPoint(x: 47, y: y + 22), to: CGPoint(x: 558, y: y + 22), color: ink, width: 0.7)
    }

    private static func drawTransactionRow(_ row: StatementRow, y: CGFloat) {
        let transaction = row.transaction
        drawText(shortDateFormatter.string(from: transaction.createdAt), in: CGRect(x: 49, y: y + 5, width: 54, height: 16), font: regularFont(6.8), color: ink)
        drawText(transaction.category.statementTitle, in: CGRect(x: 107, y: y + 3, width: 164, height: 12), font: regularFont(6.9), color: ink)
        drawText(transaction.merchant, in: CGRect(x: 107, y: y + 15, width: 164, height: 20), font: regularFont(6.1), color: secondaryInk)
        drawText(transaction.reference, in: CGRect(x: 277, y: y + 5, width: 84, height: 18), font: regularFont(6.3), color: ink)
        let debit = transaction.direction == .debit ? amountText(transaction.amountValue) : ""
        let credit = transaction.direction == .credit ? amountText(transaction.amountValue) : ""
        drawText(debit, in: CGRect(x: 367, y: y + 5, width: 54, height: 16), font: regularFont(6.6), color: ink, alignment: .right)
        drawText(credit, in: CGRect(x: 427, y: y + 5, width: 54, height: 16), font: regularFont(6.6), color: ink, alignment: .right)
        drawText(amountText(row.balance), in: CGRect(x: 487, y: y + 5, width: 69, height: 16), font: regularFont(6.6), color: ink, alignment: .right)
        drawLine(from: CGPoint(x: 47, y: y + 38), to: CGPoint(x: 558, y: y + 38), color: UIColor(white: 0.62, alpha: 1), width: 0.45)
    }

    private static func drawBalanceRow(title: String, value: Decimal, y: CGFloat) {
        drawText(title, in: CGRect(x: 107, y: y + 6, width: 300, height: 15), font: regularFont(6.9), color: ink)
        drawText(amountText(value), in: CGRect(x: 487, y: y + 6, width: 69, height: 15), font: regularFont(6.8), color: ink, alignment: .right)
        drawLine(from: CGPoint(x: 47, y: y + 27), to: CGPoint(x: 558, y: y + 27), color: ink, width: 0.7)
    }

    private static func drawVerticalStatementLabel(context: CGContext) {
        context.saveGState()
        context.translateBy(x: 23, y: 344)
        context.rotate(by: -.pi / 2)
        drawText("e-statement", in: CGRect(x: -80, y: -11, width: 160, height: 22), font: boldFont(20), color: UIColor(red: 0, green: 0.62, blue: 0.92, alpha: 1), alignment: .center)
        context.restoreGState()
    }

    private static func drawDigitalNotice(y: CGFloat) {
        drawText(
            "This electronic statement was generated from the transactions stored in the Mashreq NEO app. No physical delivery or service charge applies.",
            in: CGRect(x: 66, y: y, width: 463, height: 38),
            font: regularFont(8),
            color: secondaryInk,
            alignment: .center
        )
    }

    private static func drawFooter(pageNumber: Int, pageCount: Int) {
        drawText(
            "Page \(pageNumber) of \(pageCount)",
            in: CGRect(x: 240, y: 812, width: 115, height: 16),
            font: regularFont(7),
            color: ink,
            alignment: .center
        )
    }

    private static func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor, width: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ],
            context: nil
        )
    }

    private static func amountText(_ value: Decimal) -> String {
        MoneyText.amount(value)
    }

    private static func regularFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "29LTBukra-Regular", size: size) ?? .systemFont(ofSize: size, weight: .regular)
    }

    private static func boldFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "29LTBukra-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
}

private struct StatementSnapshot {
    let openingBalance: Decimal
    let closingBalance: Decimal
    let rows: [StatementRow]
}

private struct StatementRow {
    let transaction: Transaction
    let balance: Decimal
}

private enum EStatementPDFError: LocalizedError {
    case emptyOutput

    var errorDescription: String? {
        switch self {
        case .emptyOutput:
            "The generated e-statement is empty. Please try again."
        }
    }
}
