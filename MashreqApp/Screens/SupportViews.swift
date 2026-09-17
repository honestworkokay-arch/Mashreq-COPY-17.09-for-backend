import MessageUI
import SwiftUI

struct NotificationsView: View {
    @Environment(AppSession.self) private var session
    @State private var messageToCompose: BankingNotification?
    @State private var showsMessagesUnavailable = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "Notifications", height: 205, showsBack: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(session.bankingNotifications) { notification in
                        BankingNotificationCard(notification: notification) {
                            guard MFMessageComposeViewController.canSendText() else {
                                showsMessagesUnavailable = true
                                return
                            }
                            messageToCompose = notification
                        }
                    }

                    NotificationCard(image: "NotificationID", title: "Emirates ID has expired", subtitle: "Proceed to facial verification", action: "Update", badge: "Expired 26 Jan 2023", badgeColor: .red)
                    NotificationCard(image: "NotificationCard", title: "Platinum Elite Card", subtitle: "Ready for activation", action: "Activate now")
                    NotificationCard(image: "NotificationLoan", title: "Get instant loan of AED 50,000", subtitle: "Avail it by clicking the journey", action: "Resume now", badge: "Expiring in 10 days", badgeColor: .red)
                    NotificationCard(image: "NotificationHappiness", title: "Happiness account", subtitle: "Account activation is in progress", action: "Track status")
                }
                .padding(.horizontal, MashreqTheme.horizontalPadding)
                .padding(.top, 144)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-notifications")
        .onAppear { session.markBankingNotificationsRead() }
        .fullScreenCover(item: $messageToCompose) { notification in
            MessageComposeSheet(
                recipients: [session.profile.smsPhoneNumber],
                body: notification.message
            ) {
                messageToCompose = nil
            }
        }
        .alert("Messages is unavailable", isPresented: $showsMessagesUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A real iPhone with an active SMS or iMessage account is required.")
        }
    }
}

private struct BankingNotificationCard: View {
    let notification: BankingNotification
    let onSend: () -> Void

    var body: some View {
        PanelCard {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(MashreqTheme.orangeSoft)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(notification.kind.shortCode)
                            .font(.mashreq(size: 13, weight: .semibold))
                            .foregroundStyle(MashreqTheme.orangeDeep)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.mashreq(size: 16, weight: .semibold))
                    Text(notification.message)
                        .font(.mashreq(size: 12, weight: .regular))
                        .foregroundStyle(MashreqTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.mashreq(size: 10, weight: .regular))
                        .foregroundStyle(MashreqTheme.secondaryInk)

                    Button("Send in Messages", action: onSend)
                        .font(.mashreq(size: 12, weight: .semibold))
                        .foregroundStyle(MashreqTheme.orangeDeep)
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                if !notification.isRead {
                    Circle()
                        .fill(MashreqTheme.orangeDeep)
                        .frame(width: 8, height: 8)
                        .accessibilityLabel("Unread")
                }
            }
        }
    }
}

/// Apple не предоставляет API для автоматической отправки от iCloud.
/// Этот wrapper открывает официальный Messages-composer; пользователь сам
/// подтверждает отправку, а iOS выбирает SMS или iMessage.
private struct MessageComposeSheet: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    /// UIKit вызывает completion на main actor. Явные аннотации нужны для
    /// строгого Swift 6 concurrency-checking и исключают перенос callback
    /// между executors.
    let onFinish: @MainActor @Sendable () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) { }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        let onFinish: @MainActor @Sendable () -> Void

        init(onFinish: @escaping @MainActor @Sendable () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true, completion: onFinish)
        }
    }
}

private struct NotificationCard: View {
    let image: String
    let title: String
    let subtitle: String
    let action: String
    var badge: String?
    var badgeColor: Color = MashreqTheme.orange

    var body: some View {
        PanelCard {
            HStack(spacing: 16) {
                // Оригинальные иллюстрации вырезаны из референса без перерисовки.
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.mashreq(size: 17, weight: .bold))
                    Text(subtitle).font(.mashreq(size: 13)).foregroundStyle(MashreqTheme.secondaryInk)
                    Text(action).font(.mashreq(size: 14, weight: .semibold)).foregroundStyle(MashreqTheme.orange)
                }
                Spacer()
                if let badge {
                    Text(badge).font(.mashreq(size: 10, weight: .bold)).foregroundStyle(badgeColor).padding(8).background(badgeColor.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

struct HelpView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            MashreqHeader(title: "Help", height: 176)

            VStack(alignment: .leading, spacing: 20) {
                Text("How can we help you?").font(.mashreq(size: 23, weight: .bold))
                MashreqPrimaryButton(title: "Chat with us") { session.navigate(to: .virtualAssistant) }
                Text("Other help services").font(.mashreq(size: 21, weight: .bold))
                HelpRow(icon: "bubble.left.and.exclamationmark.bubble.right", title: "Track an existing query or complaint")
                HelpRow(icon: "person.bubble", title: "Raise a complaint")
                HelpRow(icon: "hand.raised", title: "Request a service")
                HelpRow(icon: "play.rectangle", title: "How to videos")
                Divider()
                Text("Still need help?").font(.mashreq(size: 20, weight: .bold))
                MashreqOutlineButton(title: "Call us") { }
                Spacer().frame(height: 70)
            }
            .padding(.horizontal, MashreqTheme.horizontalPadding)
            .padding(.top, 190)
        }
        .accessibilityIdentifier("screen-help")
    }
}

private struct HelpRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 15) {
            ZStack { Circle().fill(MashreqTheme.orangeSoft).frame(width: 46, height: 46); Image(systemName: icon).foregroundStyle(MashreqTheme.orange) }
            Text(title).font(.mashreq(size: 16))
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(MashreqTheme.secondaryInk)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 60).offset(y: 8) }
    }
}

private enum VirtualAssistantLayout {
    static let headerHeight: CGFloat = 128
    static let headerCurveDepth: CGFloat = 5
    static let scrollTopInset: CGFloat = 90
    static let horizontalInset: CGFloat = 18
    static let composerHeight: CGFloat = 54
    static let assistantColor = Color(hex: 0xFCE9E5)
    static let customerColor = Color(hex: 0x354A52)
    static let timestampColor = Color(hex: 0x8D9295)
}

private enum VirtualAssistantSender {
    case customer
    case assistant
}

private struct VirtualAssistantMessage: Identifiable {
    let id = UUID()
    let sender: VirtualAssistantSender
    let text: String
    let createdAt: Date

    static func openingConversation(now: Date = .now) -> [VirtualAssistantMessage] {
        [
            VirtualAssistantMessage(sender: .customer, text: "Human", createdAt: now.addingTimeInterval(-2)),
            VirtualAssistantMessage(
                sender: .assistant,
                text: "I understand you'd like to speak to our customer care team. But, I'm equipped to handle a variety of banking services.\n\nCould you please provide me with more information about your enquiry?",
                createdAt: now
            )
        ]
    }
}

private enum VirtualAssistantAction {
    case recentTransactions
    case operatorSupport
}

struct VirtualAssistantView: View {
    @Environment(AppSession.self) private var session
    @State private var draft = ""
    @State private var messages = VirtualAssistantMessage.openingConversation()
    @State private var isResponding = false
    @State private var isOperatorQueued = false
    @State private var showsQuickActions = true
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            MashreqHeader(
                title: "Mashreq Virtual Assistant",
                height: VirtualAssistantLayout.headerHeight,
                showsBack: true,
                usesReferenceBackground: true,
                titleFontSize: 14,
                titleFontWeight: .bold,
                titleOffsetY: 5,
                referenceBottomCurveDepth: VirtualAssistantLayout.headerCurveDepth,
                referenceBackAssetName: "TransactionDetailsBack",
                referenceBackOffsetY: 4
            )
            .zIndex(10)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        chatHistoryTitle

                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            VirtualAssistantMessageRow(message: message)

                            if index == 1, showsQuickActions {
                                quickActions
                            }
                        }

                        if isResponding {
                            ProgressView()
                                .tint(MashreqTheme.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }

                        Color.clear
                            .frame(height: 16)
                            .id("chat-bottom")
                    }
                    // ScrollView иначе принимает ширину самого длинного текста,
                    // из-за чего пузырь и кнопки не доходят до правого поля референса.
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, VirtualAssistantLayout.horizontalInset)
                    .padding(.top, VirtualAssistantLayout.scrollTopInset)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    composer
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: isComposerFocused) { _, focused in
                    if focused { scrollToBottom(proxy) }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen-virtual-assistant")
    }

    private var chatHistoryTitle: some View {
        HStack(spacing: 7) {
            // Иконка сохранена как точный crop из предоставленного референса.
            Image("ChatHistoryArrow")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 20, height: 29)

            Text("Chat History")
                .font(.mashreq(size: 14.5, weight: .bold))
                .foregroundStyle(MashreqTheme.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 13)
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            VirtualAssistantActionButton(title: "View Recent Transactions") {
                perform(.recentTransactions)
            }
            VirtualAssistantActionButton(title: "Connect to an operator") {
                perform(.operatorSupport)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 18)
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    showsQuickActions.toggle()
                }
            } label: {
                Image("ChatMenuReference")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Show chat actions")

            TextField("Type your Message here", text: $draft, axis: .vertical)
                .font(.mashreq(size: 16))
                .lineLimit(1...3)
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(sendDraft)

            Button(action: sendDraft) {
                Image("ChatSendReference")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .opacity(canSend ? 1 : 0.48)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .frame(minHeight: VirtualAssistantLayout.composerHeight)
        .background(Color(hex: 0xFAFAF8))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(hex: 0xD2D2D0)).frame(height: 0.7)
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponding
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        draft = ""
        isComposerFocused = false
        appendCustomerMessage(text)

        let normalized = text.lowercased()
        if normalized.contains("transaction") || normalized.contains("транзак") || normalized.contains("последн") {
            respond(with: recentTransactionsText)
        } else if normalized.contains("operator") || normalized.contains("agent") || normalized.contains("human") || normalized.contains("оператор") {
            queueOperatorSupport()
        } else {
            respond(with: "I can show your latest transactions or help you request a customer care operator. Please choose an option below.")
            showsQuickActions = true
        }
    }

    private func perform(_ action: VirtualAssistantAction) {
        guard !isResponding else { return }
        switch action {
        case .recentTransactions:
            appendCustomerMessage("View Recent Transactions")
            respond(with: recentTransactionsText)
        case .operatorSupport:
            appendCustomerMessage("Connect me to a customer care operator")
            queueOperatorSupport()
        }
    }

    private func appendCustomerMessage(_ text: String) {
        messages.append(VirtualAssistantMessage(sender: .customer, text: text, createdAt: .now))
    }

    private func respond(with text: String) {
        isResponding = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 320_000_000)
            messages.append(VirtualAssistantMessage(sender: .assistant, text: text, createdAt: .now))
            isResponding = false
        }
    }

    private func queueOperatorSupport() {
        if isOperatorQueued {
            respond(with: "Your operator request is already in the queue. Please remain in this chat.")
            return
        }
        isOperatorQueued = true
        respond(with: "I'll connect you to our customer care team. All representatives are busy right now, so please remain in this chat.")
    }

    /// Формируется из текущего AppSession: имя операции, сумма и reference
    /// обновляются вместе с общей историей и нигде не дублируются в чате.
    private var recentTransactionsText: String {
        let latest = Array(session.transactions.prefix(3))
        guard !latest.isEmpty else {
            return "You don't have any transactions to show yet."
        }

        let rows = latest.enumerated().map { index, transaction in
            "\(index + 1). \(transaction.merchant)\n\(transaction.amount)\nReference: \(transaction.reference)"
        }
        return "Here are your latest transactions:\n\n" + rows.joined(separator: "\n\n")
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 40_000_000)
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }
}

private struct VirtualAssistantMessageRow: View {
    let message: VirtualAssistantMessage

    private var isOutgoing: Bool { message.sender == .customer }

    var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 5) {
            Text(Self.timestampFormatter.string(from: message.createdAt))
                .font(.mashreq(size: 10.5))
                .foregroundStyle(VirtualAssistantLayout.timestampColor)
                .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)

            Text(message.text)
                .font(.mashreq(size: 15.5, weight: .medium))
                .foregroundStyle(isOutgoing ? .white : MashreqTheme.ink)
                .lineSpacing(4)
                .frame(maxWidth: isOutgoing ? nil : .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(isOutgoing ? VirtualAssistantLayout.customerColor : VirtualAssistantLayout.assistantColor)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .frame(maxWidth: isOutgoing ? 330 : .infinity, alignment: isOutgoing ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        .padding(.bottom, 17)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d yyyy 'at' hh:mm:ss a"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()
}

private struct VirtualAssistantActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mashreq(size: 11.5, weight: .bold))
                .foregroundStyle(MashreqTheme.orange)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(MashreqTheme.orange, lineWidth: 1.25)
                }
        }
        .buttonStyle(.plain)
    }
}
