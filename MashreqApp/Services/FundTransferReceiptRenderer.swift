import Foundation
import UIKit

/// Создаёт одностраничную A4-квитанцию поверх точного визуального шаблона из
/// приложенного PDF. Меняются только области данных конкретного перевода.
enum FundTransferReceiptRenderer {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)

    static func makePDF(for transfer: CompletedTransfer) throws -> URL {
        guard let template = UIImage(named: "ReceiptTemplatePage") else {
            throw ReceiptRenderingError.templateMissing
        }

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Fund transfer e-receipt",
            kCGPDFContextAuthor as String: "Mashreq Bank PSC",
            kCGPDFContextSubject as String: transfer.reference
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            template.draw(in: pageBounds)
            drawDynamicValues(transfer)
        }

        guard data.count > 10_000 else {
            throw ReceiptRenderingError.emptyOutput
        }

        let safeReference = transfer.reference
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeReference).pdf")

        try data.write(to: url, options: .atomic)
        return url
    }

    private static func drawDynamicValues(_ transfer: CompletedTransfer) {
        // Верхнее обращение и пояснение: очищаем только две строки данных,
        // оставляя заголовок и оригинальный логотип шаблона без изменений.
        cover(CGRect(x: 24, y: 104, width: 547, height: 55))
        draw(
            "Dear  \(transfer.senderName.uppercased()),",
            in: CGRect(x: 26, y: 110, width: 520, height: 16),
            font: regularFont(8.4),
            color: UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1)
        )
        drawIntroSentence(transfer)

        // Номер операции внутри reference-блока.
        cover(CGRect(x: 48, y: 213, width: 270, height: 22))
        draw(
            transfer.reference,
            in: CGRect(x: 49, y: 216, width: 265, height: 18),
            font: boldFont(13.4),
            color: .black
        )

        // Правая колонка Payment Summary. Подписи и сетка остаются частью
        // исходного шаблона; заменяются только значения текущего перевода.
        cover(CGRect(x: 224, y: 306, width: 334, height: 207))

        let valueColor = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
        let rows: [(String, CGFloat)] = [
            ("\(transfer.maskedSenderAccount)     (\(transfer.senderName.uppercased()))", 309),
            ("\(transfer.maskedBeneficiaryAccount)     (\(transfer.beneficiaryName.uppercased()))", 330),
            (transfer.beneficiaryBank.uppercased(), 351),
            (transfer.beneficiaryBankCountry.uppercased(), 372),
            ("AED \(transfer.formattedAmount)", 393),
            (transfer.exchangeRate, 414),
            (transfer.fxDeal, 435),
            (transfer.purposeOfPayment, 456),
            (transfer.intermediaryBank, 477),
            (transfer.noteToBeneficiary, 498)
        ]

        for (index, row) in rows.enumerated() {
            let size: CGFloat = index < 2 ? 7.6 : 8.2
            draw(
                row.0,
                in: CGRect(x: 228, y: row.1, width: 320, height: 14),
                font: boldFont(size),
                color: valueColor,
                minimumScaleFactor: 0.72
            )
        }
    }

    private static func drawIntroSentence(_ transfer: CompletedTransfer) {
        let normal = regularFont(8.2)
        let bold = boldFont(8.2)
        let color = UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2

        let result = NSMutableAttributedString(
            string: "You have initiated a fund transfer to ",
            attributes: [.font: normal, .foregroundColor: color, .paragraphStyle: paragraph]
        )
        result.append(NSAttributedString(
            string: transfer.beneficiaryName.uppercased(),
            attributes: [.font: bold, .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
        ))
        result.append(NSAttributedString(
            string: " from your account ",
            attributes: [.font: normal, .foregroundColor: color, .paragraphStyle: paragraph]
        ))
        result.append(NSAttributedString(
            string: transfer.maskedSenderAccount,
            attributes: [.font: bold, .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
        ))
        result.append(NSAttributedString(
            string: " on \(transfer.detailDate).\nPlease find the transaction details below.",
            attributes: [.font: normal, .foregroundColor: color, .paragraphStyle: paragraph]
        ))
        result.draw(
            with: CGRect(x: 26, y: 131, width: 540, height: 28),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func cover(_ rect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(rect)
    }

    private static func draw(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        minimumScaleFactor: CGFloat = 1
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byClipping

        var resolvedFont = font
        if minimumScaleFactor < 1 {
            let width = (text as NSString).size(withAttributes: [.font: font]).width
            if width > rect.width {
                let scale = max(minimumScaleFactor, rect.width / max(width, 1))
                resolvedFont = font.withSize(font.pointSize * scale)
            }
        }

        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: resolvedFont,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }

    private static func regularFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "ArialMT", size: size) ?? .systemFont(ofSize: size, weight: .regular)
    }

    private static func boldFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "Arial-BoldMT", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}

private enum ReceiptRenderingError: LocalizedError {
    case templateMissing
    case emptyOutput

    var errorDescription: String? {
        switch self {
        case .templateMissing:
            "The receipt template is missing from the application bundle."
        case .emptyOutput:
            "The generated receipt is empty."
        }
    }
}
