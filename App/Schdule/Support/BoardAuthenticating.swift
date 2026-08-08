import Foundation
import LocalAuthentication

/// Biometric gate for locked boards, behind a protocol.
///
/// Face ID cannot be driven from XCUITest on a CI simulator, so the real
/// implementation would make every screenshot run hang on a system prompt. The
/// tests inject a stub; the app injects the real thing.
protocol BoardAuthenticating: Sendable {
    func authenticate(reason: String) async -> Bool
}

struct BiometricAuthenticator: BoardAuthenticating {
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = String(localized: "Use Passcode")

        var error: NSError?
        // Device-owner authentication rather than biometrics-only: a user whose
        // Face ID fails should still reach their own data with a passcode.
        let policy = LAPolicy.deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &error) else {
            // No passcode set at all means nothing to authenticate against.
            // Refusing entry here would lock the user out of their own board
            // permanently, so an undefended device gets in.
            return true
        }

        do {
            return try await context.evaluatePolicy(policy, localizedReason: reason)
        } catch {
            return false
        }
    }
}

/// Always grants. Used under `-UITestMode` so screenshot runs do not stall on a
/// system prompt no automation can dismiss.
struct AlwaysAllowAuthenticator: BoardAuthenticating {
    func authenticate(reason: String) async -> Bool { true }
}

/// Always denies. Used to photograph the locked state.
struct AlwaysDenyAuthenticator: BoardAuthenticating {
    func authenticate(reason: String) async -> Bool { false }
}
