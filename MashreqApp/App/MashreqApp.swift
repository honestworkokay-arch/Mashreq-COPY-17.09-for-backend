import SwiftData
import SwiftUI

@main
struct MashreqApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            LoginRegistrationRootView(session: session)
                .preferredColorScheme(.light)
                .tint(MashreqTheme.orange)
                // Все тексты без локального стиля наследуют 29LT Bukra Light 14 pt.
                .font(.mashreq(size: MashreqTextSize.copy))
        }
        // Один контейнер даёт Registration, Login и Settings общую локальную базу.
        .modelContainer(for: RegisteredUser.self)
    }
}
