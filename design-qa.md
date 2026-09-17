# Design QA — first-launch registration, login and Settings

final result: blocked

## Source targets

- Registration form: the supplied Mashreq Ownership Details and contact-detail references.
- Login: the supplied UAE Mashreq login reference plus the requested password-login path.
- Settings: the supplied More, profile-management and editable contact-detail references.

## Implemented checks

- Login is always the first screen; registration opens only from `Register`
  on Login or `Register now` in Settings when no profile exists.
- Registration uses the compact 104 pt Mashreq header and returns to Login
  after saving instead of authenticating automatically.
- Registration contains First Name, Last Name, mobile number, email, IBAN,
  account number, password and password confirmation.
- The six non-secret profile/account values are stored in one SwiftData row.
- The password is stored separately in Apple Keychain with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and is never written to
  SwiftData, UserDefaults or application logs.
- Login keeps the supplied UAE layout and Face ID as the primary CTA; password
  login and registration are compact text actions below it.
- Settings now has a prominent profile card, icon-led personal/account fields,
  orange save CTA and a visually separate login-security section.
- Settings edits the same SwiftData row and provides current/new/confirm fields
  for secure password replacement.
- Registration data is converted into the existing `UserProfile`, so Overview,
  Account Details, OTP masking and transfer sender details stay synchronized.
- All three new source files are present in the Xcode target; the project file
  passes `plutil -lint`.
- Swift 6 / iOS 17 whole-source typecheck passed before this final navigation
  and Settings layout revision.
- The final revision has a clean `git diff --check` and verified call-site
  wiring. Per the user's explicit request, no new Xcode build, typecheck,
  simulator launch or screenshot capture was run after these UI changes.

## Visual QA blocker

The latest UI revision was intentionally not built or launched. Earlier,
CoreSimulator also stalled inside `simctl install` / simulator `installd` on
both tested iPhone 17 Pro runtimes. No same-device interaction pass, fresh
screenshot or 50% reference overlay is claimed for the latest revision.
