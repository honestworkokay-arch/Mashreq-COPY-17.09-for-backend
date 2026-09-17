import SwiftUI
import UIKit

/// Геометрия экрана измерена по референсу 590×1280 и хранится в одном месте,
/// чтобы дальнейшая настройка масштаба не разъезжалась между секциями.
private enum TransactionDetailsLayout {
    static let headerHeight: CGFloat = 106
    static let headerTitleSize: CGFloat = 14
    static let headerTitleOffsetY: CGFloat = -4
    static let headerCurveDepth: CGFloat = 2.5
    static let headerBackOffsetY: CGFloat = -5
    static let scrollTopInset: CGFloat = 44
    static let tabHeight: CGFloat = 55
    static let tabTitleSize: CGFloat = 15
    static let tabWidth: CGFloat = 132
    static let tabTitleOffsetY: CGFloat = 3.5
    static let summaryTopInset: CGFloat = 30.75
    static let summaryBottomInset: CGFloat = 22
    static let summaryFirstGap: CGFloat = 11.25
    static let summarySecondGap: CGFloat = 6.75
    static let beneficiaryNameSize: CGFloat = 18
    static let amountSize: CGFloat = 18
    static let amountOffsetY: CGFloat = -0.75
    static let summaryHorizontalInset: CGFloat = 23
    static let detailsHorizontalInset: CGFloat = 22.5
    static let detailsTopInset: CGFloat = 16
    static let detailFieldGap: CGFloat = 15.15
    static let detailTextSpacing: CGFloat = 1
    static let detailLabelSize: CGFloat = 11.5
    static let detailValueOffsetY: CGFloat = -1.5
    static let detailLabelColor = Color(hex: 0x707074)
}

/// Детали открываются по id зафиксированного перевода. Значения берутся из
/// CompletedTransfer, поэтому экран не содержит тестовых данных получателя.
struct TransactionDetailsView: View {
    let transferID: UUID

    @Environment(AppSession.self) private var session
    @State private var selectedTab: TransactionDetailsTab = .details
    @State private var receiptShareItem: ReceiptShareItem?
    @State private var receiptErrorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Transaction details",
                height: TransactionDetailsLayout.headerHeight,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: TransactionDetailsLayout.headerTitleSize,
                titleOffsetY: TransactionDetailsLayout.headerTitleOffsetY,
                referenceBottomCurveDepth: TransactionDetailsLayout.headerCurveDepth,
                referenceBackAssetName: "TransactionDetailsBack",
                referenceBackOffsetY: TransactionDetailsLayout.headerBackOffsetY
            )
            .zIndex(10)

            if let transfer = session.completedTransfer(id: transferID) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        tabBar

                        if selectedTab == .details {
                            detailsContent(transfer)
                        } else {
                            trackerContent(transfer)
                        }
                    }
                    // В референсе вкладки начинаются на y≈152 px: 44 pt дают
                    // такое же положение на iPhone 17 Pro без ручного offset всего ScrollView.
                    .padding(.top, TransactionDetailsLayout.scrollTopInset)
                }
            } else {
                ContentUnavailableView(
                    "Transaction unavailable",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("The saved transfer could not be found.")
                )
                .padding(.top, 101)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $receiptShareItem) { item in
            ReceiptActivityView(items: [item.url])
        }
        .alert(
            "Unable to create receipt",
            isPresented: Binding(
                get: { receiptErrorMessage != nil },
                set: { if !$0 { receiptErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { receiptErrorMessage = nil }
        } message: {
            Text(receiptErrorMessage ?? "Please try again.")
        }
        .accessibilityIdentifier("screen-transaction-details")
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TransactionDetailsTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.mashreq(size: TransactionDetailsLayout.tabTitleSize, weight: .semibold))
                        .foregroundStyle(MashreqTheme.ink)
                        // Сдвигаем только надпись, сохраняя линию вкладки на точной y-позиции.
                        .offset(y: TransactionDetailsLayout.tabTitleOffsetY)
                        .frame(maxWidth: .infinity)
                        .frame(height: TransactionDetailsLayout.tabHeight)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(tab == selectedTab ? MashreqTheme.ink : .clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
                // 132 pt дают референсную ширину вкладки ≈193 px на контрольном кадре.
                .frame(width: TransactionDetailsLayout.tabWidth)
            }

            Spacer(minLength: 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(MashreqTheme.line).frame(height: 1)
        }
    }

    private func detailsContent(_ transfer: CompletedTransfer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            transactionSummary(transfer)

            VStack(alignment: .leading, spacing: TransactionDetailsLayout.detailFieldGap) {
                detailField("Debited account", transfer.senderAccountNumber)
                detailField("Remitter bank", transfer.remitterBank)
                detailField("Beneficiary bank", transfer.beneficiaryBank)
                detailField("Beneficiary bank country", transfer.beneficiaryBankCountry)
                detailField("Beneficiary swift code", transfer.beneficiarySwiftCode)
                detailField("Beneficiary account / IBAN no.", transfer.beneficiaryIBAN)
                detailField("Amount to be transferred", "AED \(transfer.formattedAmount)")
                detailField("Fx deal", transfer.fxDeal)
                detailField("Purpose of payment", transfer.purposeOfPayment)
                detailField("Transfer type", transfer.transferType)
            }
            .padding(.horizontal, TransactionDetailsLayout.detailsHorizontalInset)
            .padding(.top, TransactionDetailsLayout.detailsTopInset)

            receiptActions(transfer)
                .padding(.horizontal, TransactionDetailsLayout.detailsHorizontalInset)
                .padding(.top, 42)
                .padding(.bottom, 40)
        }
    }

    private func transactionSummary(_ transfer: CompletedTransfer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(transfer.beneficiaryName)
                    .font(.mashreq(size: TransactionDetailsLayout.beneficiaryNameSize, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                Text(transfer.detailDate)
                    .font(.mashreq(size: MashreqTextSize.caption, weight: .light))
                    .foregroundStyle(TransactionDetailsLayout.detailLabelColor)
            }
            .padding(.bottom, TransactionDetailsLayout.summaryFirstGap)

            HStack(alignment: .center, spacing: 8) {
                UAEFlagView(size: 18)

                Text("AED \(transfer.formattedAmount)")
                    .font(.mashreq(size: TransactionDetailsLayout.amountSize, weight: .semibold))
                    .offset(y: TransactionDetailsLayout.amountOffsetY)

                Spacer(minLength: 6)

                Text("Transaction Completed")
                    .font(.mashreq(size: MashreqTextSize.nano, weight: .regular))
                    .foregroundStyle(Color(hex: 0xB26B25))
                    .padding(.horizontal, 8)
                    .frame(height: 25)
                    .background(Color(hex: 0xFFF3DD))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.bottom, TransactionDetailsLayout.summarySecondGap)

            Text("Reference number : \(transfer.reference)")
                .font(.mashreq(size: MashreqTextSize.caption, weight: .regular))
                .foregroundStyle(MashreqTheme.bodyInk)
        }
        .padding(.horizontal, TransactionDetailsLayout.summaryHorizontalInset)
        .padding(.top, TransactionDetailsLayout.summaryTopInset)
        .padding(.bottom, TransactionDetailsLayout.summaryBottomInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MashreqTheme.sectionBackground)
    }

    private func detailField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: TransactionDetailsLayout.detailTextSpacing) {
            Text(label)
                .font(.mashreq(size: TransactionDetailsLayout.detailLabelSize, weight: .regular))
                .foregroundStyle(TransactionDetailsLayout.detailLabelColor)

            Text(value)
                .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .medium))
                .foregroundStyle(MashreqTheme.ink)
                .offset(y: TransactionDetailsLayout.detailValueOffsetY)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func receiptActions(_ transfer: CompletedTransfer) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your receipts")
                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))

            Button {
                createReceipt(for: transfer)
            } label: {
                HStack {
                    Text("Fund transfer e-receipt")
                        .font(.mashreq(size: MashreqTextSize.copy, weight: .regular))
                        .foregroundStyle(MashreqTheme.ink)

                    Spacer()

                    // Тот же исходный download-asset, что и в референсном success-экране.
                    Image("TransferSuccessDownload")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 21, height: 21)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: 0xD7D7D7), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("button-fund-transfer-receipt")

            MashreqPrimaryButton(title: "Repeat transfer") {
                session.prepareRepeatTransfer(from: transfer)
            }
        }
    }

    private func trackerContent(_ transfer: CompletedTransfer) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Transfer tracker")
                .font(.mashreq(size: MashreqTextSize.titleSmall, weight: .semibold))

            HStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 29))
                    .foregroundStyle(MashreqTheme.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Transaction completed")
                        .font(.mashreq(size: MashreqTextSize.copy, weight: .semibold))
                    Text("Reference number: \(transfer.reference)")
                        .font(.mashreq(size: MashreqTextSize.bodySmall, weight: .light))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func createReceipt(for transfer: CompletedTransfer) {
        do {
            let url = try FundTransferReceiptRenderer.makePDF(for: transfer)
            receiptShareItem = ReceiptShareItem(url: url)
        } catch {
            receiptErrorMessage = error.localizedDescription
        }
    }
}

private enum TransactionDetailsTab: String, CaseIterable, Identifiable {
    case details
    case tracker

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct ReceiptShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ReceiptActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
