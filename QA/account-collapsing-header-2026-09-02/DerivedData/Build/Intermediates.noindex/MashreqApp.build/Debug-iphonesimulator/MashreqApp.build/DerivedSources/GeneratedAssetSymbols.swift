import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AccountActionCardControl" asset catalog image resource.
    static let accountActionCardControl = DeveloperToolsSupport.ImageResource(name: "AccountActionCardControl", bundle: resourceBundle)

    /// The "AccountActionDetails" asset catalog image resource.
    static let accountActionDetails = DeveloperToolsSupport.ImageResource(name: "AccountActionDetails", bundle: resourceBundle)

    /// The "AccountActionEStatements" asset catalog image resource.
    static let accountActionEStatements = DeveloperToolsSupport.ImageResource(name: "AccountActionEStatements", bundle: resourceBundle)

    /// The "AccountActionMoreOptions" asset catalog image resource.
    static let accountActionMoreOptions = DeveloperToolsSupport.ImageResource(name: "AccountActionMoreOptions", bundle: resourceBundle)

    /// The "AccountCardHero" asset catalog image resource.
    static let accountCardHero = DeveloperToolsSupport.ImageResource(name: "AccountCardHero", bundle: resourceBundle)

    /// The "AccountCompactHeader" asset catalog image resource.
    static let accountCompactHeader = DeveloperToolsSupport.ImageResource(name: "AccountCompactHeader", bundle: resourceBundle)

    /// The "AccountHeaderGradient" asset catalog image resource.
    static let accountHeaderGradient = DeveloperToolsSupport.ImageResource(name: "AccountHeaderGradient", bundle: resourceBundle)

    /// The "AlIslamiNEO" asset catalog image resource.
    static let alIslamiNEO = DeveloperToolsSupport.ImageResource(name: "AlIslamiNEO", bundle: resourceBundle)

    /// The "ApplePayMark" asset catalog image resource.
    static let applePayMark = DeveloperToolsSupport.ImageResource(name: "ApplePayMark", bundle: resourceBundle)

    /// The "CashbackCard" asset catalog image resource.
    static let cashbackCard = DeveloperToolsSupport.ImageResource(name: "CashbackCard", bundle: resourceBundle)

    /// The "DirhamMark" asset catalog image resource.
    static let dirhamMark = DeveloperToolsSupport.ImageResource(name: "DirhamMark", bundle: resourceBundle)

    /// The "EverydayCashback" asset catalog image resource.
    static let everydayCashback = DeveloperToolsSupport.ImageResource(name: "EverydayCashback", bundle: resourceBundle)

    /// The "LoginArtwork" asset catalog image resource.
    static let loginArtwork = DeveloperToolsSupport.ImageResource(name: "LoginArtwork", bundle: resourceBundle)

    /// The "LoginFaceHero" asset catalog image resource.
    static let loginFaceHero = DeveloperToolsSupport.ImageResource(name: "LoginFaceHero", bundle: resourceBundle)

    /// The "LoginFaceIDIcon" asset catalog image resource.
    static let loginFaceIDIcon = DeveloperToolsSupport.ImageResource(name: "LoginFaceIDIcon", bundle: resourceBundle)

    /// The "LoginFaceReferenceScreen" asset catalog image resource.
    static let loginFaceReferenceScreen = DeveloperToolsSupport.ImageResource(name: "LoginFaceReferenceScreen", bundle: resourceBundle)

    /// The "LoginPublicHero" asset catalog image resource.
    static let loginPublicHero = DeveloperToolsSupport.ImageResource(name: "LoginPublicHero", bundle: resourceBundle)

    /// The "LoginQuickBalanceIcon" asset catalog image resource.
    static let loginQuickBalanceIcon = DeveloperToolsSupport.ImageResource(name: "LoginQuickBalanceIcon", bundle: resourceBundle)

    /// The "LoginSecurityIcon" asset catalog image resource.
    static let loginSecurityIcon = DeveloperToolsSupport.ImageResource(name: "LoginSecurityIcon", bundle: resourceBundle)

    /// The "LoginSendMoneyIcon" asset catalog image resource.
    static let loginSendMoneyIcon = DeveloperToolsSupport.ImageResource(name: "LoginSendMoneyIcon", bundle: resourceBundle)

    /// The "MashreqLogo" asset catalog image resource.
    static let mashreqLogo = DeveloperToolsSupport.ImageResource(name: "MashreqLogo", bundle: resourceBundle)

    /// The "NeoCardArt" asset catalog image resource.
    static let neoCardArt = DeveloperToolsSupport.ImageResource(name: "NeoCardArt", bundle: resourceBundle)

    /// The "NotificationCard" asset catalog image resource.
    static let notificationCard = DeveloperToolsSupport.ImageResource(name: "NotificationCard", bundle: resourceBundle)

    /// The "NotificationHappiness" asset catalog image resource.
    static let notificationHappiness = DeveloperToolsSupport.ImageResource(name: "NotificationHappiness", bundle: resourceBundle)

    /// The "NotificationID" asset catalog image resource.
    static let notificationID = DeveloperToolsSupport.ImageResource(name: "NotificationID", bundle: resourceBundle)

    /// The "NotificationLoan" asset catalog image resource.
    static let notificationLoan = DeveloperToolsSupport.ImageResource(name: "NotificationLoan", bundle: resourceBundle)

    /// The "OverviewAddMoneyPlus" asset catalog image resource.
    static let overviewAddMoneyPlus = DeveloperToolsSupport.ImageResource(name: "OverviewAddMoneyPlus", bundle: resourceBundle)

    /// The "OverviewBanner" asset catalog image resource.
    static let overviewBanner = DeveloperToolsSupport.ImageResource(name: "OverviewBanner", bundle: resourceBundle)

    /// The "OverviewEye" asset catalog image resource.
    static let overviewEye = DeveloperToolsSupport.ImageResource(name: "OverviewEye", bundle: resourceBundle)

    /// The "OverviewHeaderChat" asset catalog image resource.
    static let overviewHeaderChat = DeveloperToolsSupport.ImageResource(name: "OverviewHeaderChat", bundle: resourceBundle)

    /// The "OverviewHeaderGradient" asset catalog image resource.
    static let overviewHeaderGradient = DeveloperToolsSupport.ImageResource(name: "OverviewHeaderGradient", bundle: resourceBundle)

    /// The "OverviewHeaderNotifications" asset catalog image resource.
    static let overviewHeaderNotifications = DeveloperToolsSupport.ImageResource(name: "OverviewHeaderNotifications", bundle: resourceBundle)

    /// The "OverviewHeaderProfile" asset catalog image resource.
    static let overviewHeaderProfile = DeveloperToolsSupport.ImageResource(name: "OverviewHeaderProfile", bundle: resourceBundle)

    /// The "OverviewMoneyInsightsArt" asset catalog image resource.
    static let overviewMoneyInsightsArt = DeveloperToolsSupport.ImageResource(name: "OverviewMoneyInsightsArt", bundle: resourceBundle)

    /// The "OverviewNavOverview" asset catalog image resource.
    static let overviewNavOverview = DeveloperToolsSupport.ImageResource(name: "OverviewNavOverview", bundle: resourceBundle)

    /// The "OverviewNavOverviewActive" asset catalog image resource.
    static let overviewNavOverviewActive = DeveloperToolsSupport.ImageResource(name: "OverviewNavOverviewActive", bundle: resourceBundle)

    /// The "OverviewNavPay" asset catalog image resource.
    static let overviewNavPay = DeveloperToolsSupport.ImageResource(name: "OverviewNavPay", bundle: resourceBundle)

    /// The "OverviewNavPayActive" asset catalog image resource.
    static let overviewNavPayActive = DeveloperToolsSupport.ImageResource(name: "OverviewNavPayActive", bundle: resourceBundle)

    /// The "OverviewNavRewards" asset catalog image resource.
    static let overviewNavRewards = DeveloperToolsSupport.ImageResource(name: "OverviewNavRewards", bundle: resourceBundle)

    /// The "OverviewNavRewardsActive" asset catalog image resource.
    static let overviewNavRewardsActive = DeveloperToolsSupport.ImageResource(name: "OverviewNavRewardsActive", bundle: resourceBundle)

    /// The "OverviewNavServices" asset catalog image resource.
    static let overviewNavServices = DeveloperToolsSupport.ImageResource(name: "OverviewNavServices", bundle: resourceBundle)

    /// The "OverviewNavServicesActive" asset catalog image resource.
    static let overviewNavServicesActive = DeveloperToolsSupport.ImageResource(name: "OverviewNavServicesActive", bundle: resourceBundle)

    /// The "OverviewNeoLockup" asset catalog image resource.
    static let overviewNeoLockup = DeveloperToolsSupport.ImageResource(name: "OverviewNeoLockup", bundle: resourceBundle)

    /// The "OverviewNextAccountPeek" asset catalog image resource.
    static let overviewNextAccountPeek = DeveloperToolsSupport.ImageResource(name: "OverviewNextAccountPeek", bundle: resourceBundle)

    /// The "PlatinumCard" asset catalog image resource.
    static let platinumCard = DeveloperToolsSupport.ImageResource(name: "PlatinumCard", bundle: resourceBundle)

    /// The "QuickRemit" asset catalog image resource.
    static let quickRemit = DeveloperToolsSupport.ImageResource(name: "QuickRemit", bundle: resourceBundle)

    /// The "ReferenceFlowBack" asset catalog image resource.
    static let referenceFlowBack = DeveloperToolsSupport.ImageResource(name: "ReferenceFlowBack", bundle: resourceBundle)

    /// The "ReferenceFlowHeaderBackground" asset catalog image resource.
    static let referenceFlowHeaderBackground = DeveloperToolsSupport.ImageResource(name: "ReferenceFlowHeaderBackground", bundle: resourceBundle)

    /// The "SolitaireCard" asset catalog image resource.
    static let solitaireCard = DeveloperToolsSupport.ImageResource(name: "SolitaireCard", bundle: resourceBundle)

    /// The "SuccessCheck" asset catalog image resource.
    static let successCheck = DeveloperToolsSupport.ImageResource(name: "SuccessCheck", bundle: resourceBundle)

    /// The "TransactionApplePay" asset catalog image resource.
    static let transactionApplePay = DeveloperToolsSupport.ImageResource(name: "TransactionApplePay", bundle: resourceBundle)

    /// The "TransactionBack" asset catalog image resource.
    static let transactionBack = DeveloperToolsSupport.ImageResource(name: "TransactionBack", bundle: resourceBundle)

    /// The "TransactionDateCalendar" asset catalog image resource.
    static let transactionDateCalendar = DeveloperToolsSupport.ImageResource(name: "TransactionDateCalendar", bundle: resourceBundle)

    /// The "TransactionFilterCalendar" asset catalog image resource.
    static let transactionFilterCalendar = DeveloperToolsSupport.ImageResource(name: "TransactionFilterCalendar", bundle: resourceBundle)

    /// The "TransferSuccessCheckRef" asset catalog image resource.
    static let transferSuccessCheckRef = DeveloperToolsSupport.ImageResource(name: "TransferSuccessCheckRef", bundle: resourceBundle)

    /// The "TransferSuccessDownload" asset catalog image resource.
    static let transferSuccessDownload = DeveloperToolsSupport.ImageResource(name: "TransferSuccessDownload", bundle: resourceBundle)

    /// The "UAEFlag" asset catalog image resource.
    static let uaeFlag = DeveloperToolsSupport.ImageResource(name: "UAEFlag", bundle: resourceBundle)

    /// The "WioDirhamSymbol" asset catalog image resource.
    static let wioDirhamSymbol = DeveloperToolsSupport.ImageResource(name: "WioDirhamSymbol", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AccountActionCardControl" asset catalog image.
    static var accountActionCardControl: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountActionCardControl)
#else
        .init()
#endif
    }

    /// The "AccountActionDetails" asset catalog image.
    static var accountActionDetails: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountActionDetails)
#else
        .init()
#endif
    }

    /// The "AccountActionEStatements" asset catalog image.
    static var accountActionEStatements: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountActionEStatements)
#else
        .init()
#endif
    }

    /// The "AccountActionMoreOptions" asset catalog image.
    static var accountActionMoreOptions: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountActionMoreOptions)
#else
        .init()
#endif
    }

    /// The "AccountCardHero" asset catalog image.
    static var accountCardHero: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountCardHero)
#else
        .init()
#endif
    }

    /// The "AccountCompactHeader" asset catalog image.
    static var accountCompactHeader: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountCompactHeader)
#else
        .init()
#endif
    }

    /// The "AccountHeaderGradient" asset catalog image.
    static var accountHeaderGradient: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accountHeaderGradient)
#else
        .init()
#endif
    }

    /// The "AlIslamiNEO" asset catalog image.
    static var alIslamiNEO: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .alIslamiNEO)
#else
        .init()
#endif
    }

    /// The "ApplePayMark" asset catalog image.
    static var applePayMark: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .applePayMark)
#else
        .init()
#endif
    }

    /// The "CashbackCard" asset catalog image.
    static var cashbackCard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cashbackCard)
#else
        .init()
#endif
    }

    /// The "DirhamMark" asset catalog image.
    static var dirhamMark: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dirhamMark)
#else
        .init()
#endif
    }

    /// The "EverydayCashback" asset catalog image.
    static var everydayCashback: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .everydayCashback)
#else
        .init()
#endif
    }

    /// The "LoginArtwork" asset catalog image.
    static var loginArtwork: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginArtwork)
#else
        .init()
#endif
    }

    /// The "LoginFaceHero" asset catalog image.
    static var loginFaceHero: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginFaceHero)
#else
        .init()
#endif
    }

    /// The "LoginFaceIDIcon" asset catalog image.
    static var loginFaceIDIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginFaceIDIcon)
#else
        .init()
#endif
    }

    /// The "LoginFaceReferenceScreen" asset catalog image.
    static var loginFaceReferenceScreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginFaceReferenceScreen)
#else
        .init()
#endif
    }

    /// The "LoginPublicHero" asset catalog image.
    static var loginPublicHero: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginPublicHero)
#else
        .init()
#endif
    }

    /// The "LoginQuickBalanceIcon" asset catalog image.
    static var loginQuickBalanceIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginQuickBalanceIcon)
#else
        .init()
#endif
    }

    /// The "LoginSecurityIcon" asset catalog image.
    static var loginSecurityIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginSecurityIcon)
#else
        .init()
#endif
    }

    /// The "LoginSendMoneyIcon" asset catalog image.
    static var loginSendMoneyIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginSendMoneyIcon)
#else
        .init()
#endif
    }

    /// The "MashreqLogo" asset catalog image.
    static var mashreqLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .mashreqLogo)
#else
        .init()
#endif
    }

    /// The "NeoCardArt" asset catalog image.
    static var neoCardArt: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .neoCardArt)
#else
        .init()
#endif
    }

    /// The "NotificationCard" asset catalog image.
    static var notificationCard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .notificationCard)
#else
        .init()
#endif
    }

    /// The "NotificationHappiness" asset catalog image.
    static var notificationHappiness: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .notificationHappiness)
#else
        .init()
#endif
    }

    /// The "NotificationID" asset catalog image.
    static var notificationID: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .notificationID)
#else
        .init()
#endif
    }

    /// The "NotificationLoan" asset catalog image.
    static var notificationLoan: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .notificationLoan)
#else
        .init()
#endif
    }

    /// The "OverviewAddMoneyPlus" asset catalog image.
    static var overviewAddMoneyPlus: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewAddMoneyPlus)
#else
        .init()
#endif
    }

    /// The "OverviewBanner" asset catalog image.
    static var overviewBanner: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewBanner)
#else
        .init()
#endif
    }

    /// The "OverviewEye" asset catalog image.
    static var overviewEye: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewEye)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderChat" asset catalog image.
    static var overviewHeaderChat: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewHeaderChat)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderGradient" asset catalog image.
    static var overviewHeaderGradient: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewHeaderGradient)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderNotifications" asset catalog image.
    static var overviewHeaderNotifications: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewHeaderNotifications)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderProfile" asset catalog image.
    static var overviewHeaderProfile: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewHeaderProfile)
#else
        .init()
#endif
    }

    /// The "OverviewMoneyInsightsArt" asset catalog image.
    static var overviewMoneyInsightsArt: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewMoneyInsightsArt)
#else
        .init()
#endif
    }

    /// The "OverviewNavOverview" asset catalog image.
    static var overviewNavOverview: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavOverview)
#else
        .init()
#endif
    }

    /// The "OverviewNavOverviewActive" asset catalog image.
    static var overviewNavOverviewActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavOverviewActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavPay" asset catalog image.
    static var overviewNavPay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavPay)
#else
        .init()
#endif
    }

    /// The "OverviewNavPayActive" asset catalog image.
    static var overviewNavPayActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavPayActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavRewards" asset catalog image.
    static var overviewNavRewards: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavRewards)
#else
        .init()
#endif
    }

    /// The "OverviewNavRewardsActive" asset catalog image.
    static var overviewNavRewardsActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavRewardsActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavServices" asset catalog image.
    static var overviewNavServices: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavServices)
#else
        .init()
#endif
    }

    /// The "OverviewNavServicesActive" asset catalog image.
    static var overviewNavServicesActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNavServicesActive)
#else
        .init()
#endif
    }

    /// The "OverviewNeoLockup" asset catalog image.
    static var overviewNeoLockup: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNeoLockup)
#else
        .init()
#endif
    }

    /// The "OverviewNextAccountPeek" asset catalog image.
    static var overviewNextAccountPeek: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .overviewNextAccountPeek)
#else
        .init()
#endif
    }

    /// The "PlatinumCard" asset catalog image.
    static var platinumCard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .platinumCard)
#else
        .init()
#endif
    }

    /// The "QuickRemit" asset catalog image.
    static var quickRemit: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .quickRemit)
#else
        .init()
#endif
    }

    /// The "ReferenceFlowBack" asset catalog image.
    static var referenceFlowBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .referenceFlowBack)
#else
        .init()
#endif
    }

    /// The "ReferenceFlowHeaderBackground" asset catalog image.
    static var referenceFlowHeaderBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .referenceFlowHeaderBackground)
#else
        .init()
#endif
    }

    /// The "SolitaireCard" asset catalog image.
    static var solitaireCard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .solitaireCard)
#else
        .init()
#endif
    }

    /// The "SuccessCheck" asset catalog image.
    static var successCheck: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .successCheck)
#else
        .init()
#endif
    }

    /// The "TransactionApplePay" asset catalog image.
    static var transactionApplePay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transactionApplePay)
#else
        .init()
#endif
    }

    /// The "TransactionBack" asset catalog image.
    static var transactionBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transactionBack)
#else
        .init()
#endif
    }

    /// The "TransactionDateCalendar" asset catalog image.
    static var transactionDateCalendar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transactionDateCalendar)
#else
        .init()
#endif
    }

    /// The "TransactionFilterCalendar" asset catalog image.
    static var transactionFilterCalendar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transactionFilterCalendar)
#else
        .init()
#endif
    }

    /// The "TransferSuccessCheckRef" asset catalog image.
    static var transferSuccessCheckRef: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transferSuccessCheckRef)
#else
        .init()
#endif
    }

    /// The "TransferSuccessDownload" asset catalog image.
    static var transferSuccessDownload: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .transferSuccessDownload)
#else
        .init()
#endif
    }

    /// The "UAEFlag" asset catalog image.
    static var uaeFlag: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .uaeFlag)
#else
        .init()
#endif
    }

    /// The "WioDirhamSymbol" asset catalog image.
    static var wioDirhamSymbol: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wioDirhamSymbol)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AccountActionCardControl" asset catalog image.
    static var accountActionCardControl: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountActionCardControl)
#else
        .init()
#endif
    }

    /// The "AccountActionDetails" asset catalog image.
    static var accountActionDetails: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountActionDetails)
#else
        .init()
#endif
    }

    /// The "AccountActionEStatements" asset catalog image.
    static var accountActionEStatements: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountActionEStatements)
#else
        .init()
#endif
    }

    /// The "AccountActionMoreOptions" asset catalog image.
    static var accountActionMoreOptions: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountActionMoreOptions)
#else
        .init()
#endif
    }

    /// The "AccountCardHero" asset catalog image.
    static var accountCardHero: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountCardHero)
#else
        .init()
#endif
    }

    /// The "AccountCompactHeader" asset catalog image.
    static var accountCompactHeader: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountCompactHeader)
#else
        .init()
#endif
    }

    /// The "AccountHeaderGradient" asset catalog image.
    static var accountHeaderGradient: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .accountHeaderGradient)
#else
        .init()
#endif
    }

    /// The "AlIslamiNEO" asset catalog image.
    static var alIslamiNEO: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .alIslamiNEO)
#else
        .init()
#endif
    }

    /// The "ApplePayMark" asset catalog image.
    static var applePayMark: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .applePayMark)
#else
        .init()
#endif
    }

    /// The "CashbackCard" asset catalog image.
    static var cashbackCard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cashbackCard)
#else
        .init()
#endif
    }

    /// The "DirhamMark" asset catalog image.
    static var dirhamMark: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dirhamMark)
#else
        .init()
#endif
    }

    /// The "EverydayCashback" asset catalog image.
    static var everydayCashback: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .everydayCashback)
#else
        .init()
#endif
    }

    /// The "LoginArtwork" asset catalog image.
    static var loginArtwork: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginArtwork)
#else
        .init()
#endif
    }

    /// The "LoginFaceHero" asset catalog image.
    static var loginFaceHero: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginFaceHero)
#else
        .init()
#endif
    }

    /// The "LoginFaceIDIcon" asset catalog image.
    static var loginFaceIDIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginFaceIDIcon)
#else
        .init()
#endif
    }

    /// The "LoginFaceReferenceScreen" asset catalog image.
    static var loginFaceReferenceScreen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginFaceReferenceScreen)
#else
        .init()
#endif
    }

    /// The "LoginPublicHero" asset catalog image.
    static var loginPublicHero: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginPublicHero)
#else
        .init()
#endif
    }

    /// The "LoginQuickBalanceIcon" asset catalog image.
    static var loginQuickBalanceIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginQuickBalanceIcon)
#else
        .init()
#endif
    }

    /// The "LoginSecurityIcon" asset catalog image.
    static var loginSecurityIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginSecurityIcon)
#else
        .init()
#endif
    }

    /// The "LoginSendMoneyIcon" asset catalog image.
    static var loginSendMoneyIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginSendMoneyIcon)
#else
        .init()
#endif
    }

    /// The "MashreqLogo" asset catalog image.
    static var mashreqLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .mashreqLogo)
#else
        .init()
#endif
    }

    /// The "NeoCardArt" asset catalog image.
    static var neoCardArt: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .neoCardArt)
#else
        .init()
#endif
    }

    /// The "NotificationCard" asset catalog image.
    static var notificationCard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .notificationCard)
#else
        .init()
#endif
    }

    /// The "NotificationHappiness" asset catalog image.
    static var notificationHappiness: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .notificationHappiness)
#else
        .init()
#endif
    }

    /// The "NotificationID" asset catalog image.
    static var notificationID: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .notificationID)
#else
        .init()
#endif
    }

    /// The "NotificationLoan" asset catalog image.
    static var notificationLoan: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .notificationLoan)
#else
        .init()
#endif
    }

    /// The "OverviewAddMoneyPlus" asset catalog image.
    static var overviewAddMoneyPlus: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewAddMoneyPlus)
#else
        .init()
#endif
    }

    /// The "OverviewBanner" asset catalog image.
    static var overviewBanner: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewBanner)
#else
        .init()
#endif
    }

    /// The "OverviewEye" asset catalog image.
    static var overviewEye: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewEye)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderChat" asset catalog image.
    static var overviewHeaderChat: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewHeaderChat)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderGradient" asset catalog image.
    static var overviewHeaderGradient: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewHeaderGradient)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderNotifications" asset catalog image.
    static var overviewHeaderNotifications: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewHeaderNotifications)
#else
        .init()
#endif
    }

    /// The "OverviewHeaderProfile" asset catalog image.
    static var overviewHeaderProfile: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewHeaderProfile)
#else
        .init()
#endif
    }

    /// The "OverviewMoneyInsightsArt" asset catalog image.
    static var overviewMoneyInsightsArt: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewMoneyInsightsArt)
#else
        .init()
#endif
    }

    /// The "OverviewNavOverview" asset catalog image.
    static var overviewNavOverview: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavOverview)
#else
        .init()
#endif
    }

    /// The "OverviewNavOverviewActive" asset catalog image.
    static var overviewNavOverviewActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavOverviewActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavPay" asset catalog image.
    static var overviewNavPay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavPay)
#else
        .init()
#endif
    }

    /// The "OverviewNavPayActive" asset catalog image.
    static var overviewNavPayActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavPayActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavRewards" asset catalog image.
    static var overviewNavRewards: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavRewards)
#else
        .init()
#endif
    }

    /// The "OverviewNavRewardsActive" asset catalog image.
    static var overviewNavRewardsActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavRewardsActive)
#else
        .init()
#endif
    }

    /// The "OverviewNavServices" asset catalog image.
    static var overviewNavServices: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavServices)
#else
        .init()
#endif
    }

    /// The "OverviewNavServicesActive" asset catalog image.
    static var overviewNavServicesActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNavServicesActive)
#else
        .init()
#endif
    }

    /// The "OverviewNeoLockup" asset catalog image.
    static var overviewNeoLockup: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNeoLockup)
#else
        .init()
#endif
    }

    /// The "OverviewNextAccountPeek" asset catalog image.
    static var overviewNextAccountPeek: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .overviewNextAccountPeek)
#else
        .init()
#endif
    }

    /// The "PlatinumCard" asset catalog image.
    static var platinumCard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .platinumCard)
#else
        .init()
#endif
    }

    /// The "QuickRemit" asset catalog image.
    static var quickRemit: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .quickRemit)
#else
        .init()
#endif
    }

    /// The "ReferenceFlowBack" asset catalog image.
    static var referenceFlowBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .referenceFlowBack)
#else
        .init()
#endif
    }

    /// The "ReferenceFlowHeaderBackground" asset catalog image.
    static var referenceFlowHeaderBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .referenceFlowHeaderBackground)
#else
        .init()
#endif
    }

    /// The "SolitaireCard" asset catalog image.
    static var solitaireCard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .solitaireCard)
#else
        .init()
#endif
    }

    /// The "SuccessCheck" asset catalog image.
    static var successCheck: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .successCheck)
#else
        .init()
#endif
    }

    /// The "TransactionApplePay" asset catalog image.
    static var transactionApplePay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transactionApplePay)
#else
        .init()
#endif
    }

    /// The "TransactionBack" asset catalog image.
    static var transactionBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transactionBack)
#else
        .init()
#endif
    }

    /// The "TransactionDateCalendar" asset catalog image.
    static var transactionDateCalendar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transactionDateCalendar)
#else
        .init()
#endif
    }

    /// The "TransactionFilterCalendar" asset catalog image.
    static var transactionFilterCalendar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transactionFilterCalendar)
#else
        .init()
#endif
    }

    /// The "TransferSuccessCheckRef" asset catalog image.
    static var transferSuccessCheckRef: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transferSuccessCheckRef)
#else
        .init()
#endif
    }

    /// The "TransferSuccessDownload" asset catalog image.
    static var transferSuccessDownload: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .transferSuccessDownload)
#else
        .init()
#endif
    }

    /// The "UAEFlag" asset catalog image.
    static var uaeFlag: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .uaeFlag)
#else
        .init()
#endif
    }

    /// The "WioDirhamSymbol" asset catalog image.
    static var wioDirhamSymbol: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wioDirhamSymbol)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

