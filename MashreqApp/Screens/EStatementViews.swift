import PDFKit
import SwiftUI

struct EStatementRequestView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var step: EStatementRequestStep = .selection
    @State private var selectionMode: EStatementSelectionMode = .duration
    @State private var duration: EStatementDuration = .threeMonths
    @State private var fromDate = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
    @State private var toDate = Date.now
    @State private var activeSheet: EStatementSheet?
    @State private var generatedStatement: GeneratedEStatement?
    @State private var errorMessage: String?
    @State private var isGenerating = false

    private var selectedPeriod: EStatementPeriod {
        switch selectionMode {
        case .duration:
            return duration.period(endingAt: .now)
        case .dateRange:
            let start = min(fromDate, toDate)
            let end = max(fromDate, toDate)
            return EStatementPeriod(startDate: start, endDate: end)
        }
    }

    private var selectedTransactionCount: Int {
        session.transactions.filter { transaction in
            !transaction.isProcessing && selectedPeriod.contains(transaction.createdAt)
        }.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                Group {
                    switch step {
                    case .selection:
                        selectionContent
                    case .review:
                        reviewContent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 164)
                .padding(.bottom, 116)
            }

            MashreqHeader(
                title: "Statement request",
                height: 136,
                showsBack: true,
                usesReferenceBackground: true,
                onBack: handleBack,
                content: {
                    ProgressLine(progress: step == .selection ? 0.68 : 1)
                        .padding(.horizontal, 24)
                }
            )
            .zIndex(10)

            VStack(spacing: 0) {
                Spacer()
                MashreqPrimaryButton(
                    title: step == .selection
                        ? "Next"
                        : (isGenerating ? "Generating..." : "Generate e-statement")
                ) {
                    if step == .selection {
                        step = .review
                    } else {
                        generateStatement()
                    }
                }
                .disabled(isGenerating)
                .opacity(isGenerating ? 0.68 : 1)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color.white)
            }
            .zIndex(8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-e-statement-request")
        .mashreqEdgeToEdgeBottomSheet(
            item: $activeSheet,
            height: { _ in 330 }
        ) { sheet in
            switch sheet {
            case .duration:
                durationSheet
            }
        }
        .fullScreenCover(item: $generatedStatement) { statement in
            EStatementPreviewSheet(statement: statement)
        }
        .alert(
            "Unable to generate e-statement",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var selectionContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Select details for e-statement")
                .font(.mashreq(size: 25, weight: .semibold))
                .foregroundStyle(MashreqTheme.ink)

            Text("Your statement will be generated as a PDF using your posted account transactions.")
                .font(.mashreq(size: 16, weight: .regular))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .lineSpacing(4)
                .padding(.top, 14)

            Text("Select the duration for statement generation")
                .font(.mashreq(size: 20, weight: .semibold))
                .foregroundStyle(MashreqTheme.ink)
                .padding(.top, 36)

            statementOptionCard(
                title: "By duration",
                subtitle: duration.title,
                isSelected: selectionMode == .duration
            ) {
                selectionMode = .duration
                activeSheet = .duration
            }
            .padding(.top, 22)

            statementOptionCard(
                title: "By date range",
                subtitle: selectionMode == .dateRange ? selectedPeriod.displayTitle : nil,
                isSelected: selectionMode == .dateRange
            ) {
                selectionMode = .dateRange
            }
            .padding(.top, 14)

            if selectionMode == .dateRange {
                dateRangeFields
                    .padding(.top, 18)
            }

            statementInformationCard
                .padding(.top, 30)
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("In conclusion")
                .font(.mashreq(size: 25, weight: .semibold))
                .foregroundStyle(MashreqTheme.ink)

            reviewCard {
                HStack(spacing: 17) {
                    Image("AccountActionEStatements")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("E-statement period")
                            .font(.mashreq(size: 14, weight: .regular))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                        Text(selectedPeriod.displayTitle)
                            .font(.mashreq(size: 16, weight: .semibold))
                            .foregroundStyle(MashreqTheme.ink)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, 24)

            reviewCard {
                HStack(spacing: 17) {
                    UAEFlagView(size: 52)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("For Current Account")
                            .font(.mashreq(size: 14, weight: .regular))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                        Text("Account number | \(session.profile.accountNumber)")
                            .font(.mashreq(size: 16, weight: .semibold))
                            .foregroundStyle(MashreqTheme.ink)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, 15)

            reviewCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("PDF statement details")
                        .font(.mashreq(size: 19, weight: .semibold))
                    detailLine(label: "Currency", value: "AED")
                    detailLine(label: "Posted transactions", value: "\(selectedTransactionCount)")
                    detailLine(label: "Delivery", value: "Instant PDF")
                    detailLine(label: "Service charge", value: "AED 0.00")
                }
            }
            .padding(.top, 30)

            Text("The generated PDF can be previewed, shared or saved to Files.")
                .font(.mashreq(size: 13, weight: .regular))
                .foregroundStyle(MashreqTheme.secondaryInk)
                .padding(.top, 18)
        }
    }

    private func statementOptionCard(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image("TransactionDateCalendar")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 33, height: 33)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.mashreq(size: 17, weight: .regular))
                        .foregroundStyle(MashreqTheme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.mashreq(size: 12, weight: .regular))
                            .foregroundStyle(MashreqTheme.secondaryInk)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? MashreqTheme.ink : MashreqTheme.line, lineWidth: isSelected ? 1.4 : 0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private var dateRangeFields: some View {
        VStack(spacing: 12) {
            HStack {
                Text("From")
                    .font(.mashreq(size: 15, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
                DatePicker("", selection: $fromDate, in: ...toDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(MashreqTheme.orangeDeep)
            }

            HStack {
                Text("To")
                    .font(.mashreq(size: 15, weight: .regular))
                    .foregroundStyle(MashreqTheme.ink)
                Spacer()
                DatePicker("", selection: $toDate, in: fromDate...Date.now, displayedComponents: .date)
                    .labelsHidden()
                    .tint(MashreqTheme.orangeDeep)
            }
        }
        .padding(16)
        .background(Color(hex: 0xFAFAFA))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(MashreqTheme.line, lineWidth: 0.8)
        }
    }

    private var statementInformationCard: some View {
        HStack(alignment: .top, spacing: 15) {
            Image("AccountActionEStatements")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 43, height: 43)

            VStack(alignment: .leading, spacing: 7) {
                Text("Electronic delivery")
                    .font(.mashreq(size: 17, weight: .semibold))
                Text("The document is generated immediately and remains on your device until you share or save it.")
                    .font(.mashreq(size: 13, weight: .regular))
                    .foregroundStyle(MashreqTheme.secondaryInk)
                    .lineSpacing(3)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xFFF8F4))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(hex: 0xF3D9CC), lineWidth: 0.8)
        }
    }

    private func reviewCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(MashreqTheme.line, lineWidth: 0.8)
            }
    }

    private func detailLine(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(MashreqTheme.secondaryInk)
            Spacer()
            Text(value)
                .font(.mashreq(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
        }
        .font(.mashreq(size: 14, weight: .regular))
    }

    private var durationSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(hex: 0xD6D6D6))
                .frame(width: 48, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text("Select the duration")
                .font(.mashreq(size: 24, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 10)

            ForEach(EStatementDuration.allCases) { option in
                Button {
                    duration = option
                    selectionMode = .duration
                    activeSheet = nil
                } label: {
                    HStack {
                        Text(option.title)
                            .font(.mashreq(size: 17, weight: .regular))
                            .foregroundStyle(MashreqTheme.ink)
                        Spacer()
                        if option == duration {
                            Text("Selected")
                                .font(.mashreq(size: 12, weight: .semibold))
                                .foregroundStyle(MashreqTheme.orangeDeep)
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 70)
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) {
                        Divider().padding(.leading, 24)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.ignoresSafeArea())
    }

    private func handleBack() {
        if step == .review {
            step = .selection
        } else {
            dismiss()
        }
    }

    private func generateStatement() {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let url = try EStatementPDFRenderer.makePDF(
                profile: session.profile,
                accountBalance: session.accountBalance,
                transactions: session.transactions,
                period: selectedPeriod
            )
            generatedStatement = GeneratedEStatement(url: url, period: selectedPeriod)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum EStatementRequestStep {
    case selection
    case review
}

private enum EStatementSelectionMode {
    case duration
    case dateRange
}

private enum EStatementSheet: String, Identifiable {
    case duration
    var id: String { rawValue }
}

private enum EStatementDuration: Int, CaseIterable, Identifiable {
    case oneMonth = 1
    case threeMonths = 3
    case sixMonths = 6
    case oneYear = 12

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .oneMonth: "Last 1 month"
        case .threeMonths: "Last 3 months"
        case .sixMonths: "Last 6 months"
        case .oneYear: "Last 1 year"
        }
    }

    func period(endingAt endDate: Date, calendar: Calendar = .current) -> EStatementPeriod {
        let start = calendar.date(byAdding: .month, value: -rawValue, to: endDate) ?? endDate
        return EStatementPeriod(startDate: start, endDate: endDate)
    }
}

private struct GeneratedEStatement: Identifiable {
    let id = UUID()
    let url: URL
    let period: EStatementPeriod
}

private struct EStatementPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let statement: GeneratedEStatement

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") { dismiss() }
                    .font(.mashreq(size: 14, weight: .medium))
                    .foregroundStyle(MashreqTheme.orangeDeep)

                Spacer()

                VStack(spacing: 2) {
                    Text("E-statement")
                        .font(.mashreq(size: 16, weight: .semibold))
                    Text(statement.period.displayTitle)
                        .font(.mashreq(size: 10, weight: .regular))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                }

                Spacer()

                ShareLink(item: statement.url) {
                    Text("Share")
                        .font(.mashreq(size: 14, weight: .medium))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .background(Color.white)
            .overlay(alignment: .bottom) { Divider() }

            EStatementPDFView(url: statement.url)
                .background(Color(hex: 0xEDEDED))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .accessibilityIdentifier("sheet-e-statement-preview")
    }
}

private struct EStatementPDFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor(white: 0.93, alpha: 1)
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
