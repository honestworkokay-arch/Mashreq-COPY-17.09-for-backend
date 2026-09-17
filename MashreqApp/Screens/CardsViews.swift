import SwiftUI

struct CardsListView: View {
    @Environment(AppSession.self) private var session

    private let cards = [
        ("Platinum Elite Credit Card", "AED 20,000.00", "PlatinumCard"),
        ("noon VIP Credit Card", "AED 2,500.00", "CashbackCard"),
        ("Solitaire Credit Card", "AED 7,500.00", "SolitaireCard")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "Cards", height: 218, showsBack: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    PanelCard {
                        VStack(alignment: .leading, spacing: 11) {
                            Text("3 Cards").font(.mashreq(size: 25, weight: .bold))
                            CardBalanceRow(label: "Outstanding balance", amount: "AED 30,000.00")
                            CardBalanceRow(label: "Available limit", amount: "AED 30,000.00")
                        }
                    }

                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        Button { session.navigate(to: .cardDetails) } label: {
                            PanelCard {
                                HStack(spacing: 14) {
                                    Image(card.2).resizable().scaledToFill().frame(width: 66, height: 48).clipShape(RoundedRectangle(cornerRadius: 4))
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(card.0).font(.mashreq(size: 15, weight: .semibold)).lineLimit(1)
                                            Spacer()
                                            Text("••••1234").font(.mashreq(size: 11)).foregroundStyle(MashreqTheme.secondaryInk)
                                        }
                                        HStack {
                                            Text(card.1).font(.mashreq(size: 21, weight: .bold))
                                            Spacer()
                                            Text("Primary").font(.mashreq(size: 11, weight: .medium)).foregroundStyle(MashreqTheme.orange).padding(7).background(MashreqTheme.orangeSoft).clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("card-row-\(index)")
                    }

                    Button { session.navigate(to: .selectCreditCard) } label: {
                        InfoPromoRow(image: "CashbackCard", title: "Apply for a card now", subtitle: "It’s instant and paperless")
                    }
                    .buttonStyle(.plain)
                    InfoPromoRow(image: "QuickRemit", title: "Get a supplementary card", subtitle: "Apply in just a few clicks")
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 140)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-cards")
    }
}

private struct CardBalanceRow: View {
    let label: String
    let amount: String

    var body: some View {
        HStack {
            Text(label).font(.mashreq(size: 14))
            Spacer()
            Text(amount).font(.mashreq(size: 18, weight: .bold))
        }
    }
}

private struct InfoPromoRow: View {
    let image: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(image).resizable().scaledToFill().frame(width: 78, height: 70).clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.mashreq(size: 17, weight: .bold))
                Text(subtitle).font(.mashreq(size: 13)).foregroundStyle(MashreqTheme.secondaryInk)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(MashreqTheme.secondaryInk)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .mashreqCardShadow()
    }
}

struct CardDetailsView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "Solitaire", height: 415, showsBack: true, content: {
                VStack(spacing: 8) {
                    Text("Total Available Limit").font(.mashreq(size: 14, weight: .medium)).foregroundStyle(.white)
                    Text("AED 7,500.00").font(.mashreq(size: 27, weight: .bold)).foregroundStyle(.white)
                    Text("Total Credit Limit AED 50,000\nOutstanding Balance AED 10,000")
                        .font(.mashreq(size: 14, weight: .semibold)).foregroundStyle(.white).multilineTextAlignment(.center)
                    Image("SolitaireCard").resizable().scaledToFit().frame(width: 285, height: 130)
                }
            })

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    PanelCard {
                        HStack {
                            ActionIcon(systemName: "info.circle", title: "Card\nDetails")
                            ActionIcon(systemName: "percent", title: "Instant\nCash")
                            ActionIcon(systemName: "creditcard.and.123", title: "Card\nControl")
                            ActionIcon(systemName: "ellipsis", title: "More\nOptions")
                        }
                    }

                    SectionTitle(title: "Transactions", actionTitle: "Filter") { }
                    HStack(spacing: 10) {
                        Text("All").foregroundStyle(MashreqTheme.orange).padding(.horizontal, 14).frame(height: 38).overlay(RoundedRectangle(cornerRadius: 8).stroke(MashreqTheme.orange))
                        Text("Easy Payment Plan").foregroundStyle(MashreqTheme.secondaryInk).padding(.horizontal, 14).frame(height: 38).overlay(RoundedRectangle(cornerRadius: 8).stroke(MashreqTheme.secondaryInk))
                        Spacer()
                    }
                    HStack { Image(systemName: "calendar"); Text("21st February 2023") }
                        .font(.mashreq(size: 13)).foregroundStyle(MashreqTheme.secondaryInk).frame(maxWidth: .infinity, alignment: .leading)

                    TransactionRow(transaction: Transaction(reference: "123456789", merchant: "AMAZONICO RESTAURANT DUBAI 123", amount: "- AED 250.00", isProcessing: false))
                    TransactionRow(transaction: Transaction(reference: "511629643", merchant: "SHOPPING", amount: "- AED 78.23", isProcessing: false))

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Last statement balance").font(.mashreq(size: 13)).foregroundStyle(MashreqTheme.secondaryInk)
                            Text("AED 12,500.00").font(.mashreq(size: 20, weight: .bold))
                        }
                        Spacer()
                        MashreqPrimaryButton(title: "Pay Now") { }.frame(width: 145)
                    }
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 330)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-card-details")
    }
}

struct SelectCreditCardView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "Select Credit Card", height: 205, showsBack: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack(spacing: 42) {
                        Text("Neo").foregroundStyle(MashreqTheme.orange).fontWeight(.bold)
                        Text("Al Islami").foregroundStyle(MashreqTheme.secondaryInk)
                    }
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottom) { Capsule().fill(MashreqTheme.orange).frame(width: 64, height: 3).offset(x: -47, y: 12) }

                    PanelCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Image("CashbackCard").resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 190)
                            Text("Recommended for you").font(.mashreq(size: 12, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 7).background(MashreqTheme.orange).clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Cashback Credit Card").font(.mashreq(size: 22, weight: .bold))
                            Text("Min. monthly salary: AED 5,000").font(.mashreq(size: 14))
                            BenefitLine(text: "AED 100 cashback (min. retail spend of AED 4,500 required in the first 2 months)")
                            BenefitLine(text: "20% cashback at Zomato and more...")
                            BenefitLine(text: "5% on dining spends")
                        }
                    }

                    CreditCardOption(image: "SolitaireCard", title: "Solitaire Credit Card", subtitle: "Made exclusively for you")
                    CreditCardOption(image: "PlatinumCard", title: "Platinum Elite Credit Card", subtitle: "The perfect partner for the elite")
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 142)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-select-card")
    }
}

private struct BenefitLine: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle").foregroundStyle(MashreqTheme.orange)
            Text(text).font(.mashreq(size: 13))
        }
    }
}

private struct CreditCardOption: View {
    let image: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(image).resizable().scaledToFit().frame(width: 120, height: 75)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.mashreq(size: 17, weight: .bold))
                Text(subtitle).font(.mashreq(size: 13)).foregroundStyle(MashreqTheme.secondaryInk)
            }
            Spacer()
        }
        .padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 7)).mashreqCardShadow()
    }
}
