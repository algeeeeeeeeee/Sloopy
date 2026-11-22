import CoreFoundation
import Darwin
import FamilyControls
import Foundation
import OSLog

@MainActor
enum SloopyDiagnostics {
    private final class TimeoutGate<Value: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Value?, Never>?

        init(_ continuation: CheckedContinuation<Value?, Never>) {
            self.continuation = continuation
        }

        func resolve(_ value: Value?) {
            lock.lock()
            let pendingContinuation = continuation
            continuation = nil
            lock.unlock()

            pendingContinuation?.resume(returning: value)
        }
    }

    /// Returns at the deadline even if the operation does not cooperate with cancellation.
    static func withTimeout<Value: Sendable>(
        seconds: UInt64,
        operation: @escaping @MainActor () async -> Value
    ) async -> Value? {
        await withCheckedContinuation { continuation in
            let gate = TimeoutGate<Value>(continuation)

            Task { @MainActor in
                gate.resolve(await operation())
            }

            Task {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                gate.resolve(nil)
            }
        }
    }

    static func authorizationFailureReport(for error: Error) -> String {
        let nsError = error as NSError
        let underlyingError = nsError.userInfo[NSUnderlyingErrorKey].map {
            String(reflecting: $0)
        } ?? "tidak ada"

        return """
        String(reflecting: error):
        \(String(reflecting: error))

        NSError:
        domain: \(nsError.domain)
        code: \(nsError.code)
        userInfo: \(String(reflecting: nsError.userInfo))
        NSUnderlyingErrorKey: \(underlyingError)

        AuthorizationCenter.shared.authorizationStatus:
        \(String(reflecting: AuthorizationCenter.shared.authorizationStatus))
        """
    }

    static func captureCurrentProcessLogs(
        around requestStartedAt: Date
    ) async -> (text: String, entryCount: Int) {
        let windowStart = requestStartedAt.addingTimeInterval(-2)
        let windowEnd = requestStartedAt.addingTimeInterval(2)

        // Wait until the requested two-second post-request window has elapsed.
        let remainingInterval = windowEnd.timeIntervalSinceNow
        if remainingInterval > 0 {
            let nanoseconds = UInt64(remainingInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }

        return await Task.detached(priority: .utility) {
            do {
                let store = try OSLogStore(scope: .currentProcessIdentifier)
                let position = store.position(date: windowStart)
                let entries = try store.getEntries(
                    with: [],
                    at: position,
                    matching: nil
                )
                let formatter = ISO8601DateFormatter()
                var lines: [String] = []

                for entry in entries {
                    guard entry.date >= windowStart else { continue }
                    guard entry.date <= windowEnd else { break }

                    let payload = entry as? OSLogEntryWithPayload
                    let subsystem = payload?.subsystem ?? "-"
                    let category = payload?.category ?? "-"
                    let timestamp = formatter.string(from: entry.date)

                    lines.append(
                        "\(timestamp) | \(subsystem) | \(category) | \(entry.composedMessage)"
                    )
                }

                let entryCount = lines.count
                let limitedOutput = lines.prefix(200).joined(separator: "\n")
                let output = String(limitedOutput.prefix(12_000))

                return (
                    output.isEmpty ? "Tidak ada entri log dalam rentang waktu." : output,
                    entryCount
                )
            } catch {
                return (String(reflecting: error), 0)
            }
        }.value
    }

    static func runtimeEntitlementsReport() -> String {
        typealias CreateTaskFunction = @convention(c) (CFAllocator?) -> Unmanaged<CFTypeRef>?
        typealias CopyEntitlementFunction = @convention(c) (
            CFTypeRef,
            CFString,
            UnsafeMutablePointer<Unmanaged<CFError>?>?
        ) -> Unmanaged<CFTypeRef>?

        let securityFrameworkPath = "/System/Library/Frameworks/Security.framework/Security"

        guard let securityHandle = dlopen(securityFrameworkPath, RTLD_NOW) else {
            return loaderErrorMessage()
        }
        defer { dlclose(securityHandle) }

        _ = dlerror()
        guard let createTaskSymbol = dlsym(securityHandle, "SecTaskCreateFromSelf") else {
            return loaderErrorMessage()
        }

        _ = dlerror()
        guard let copyEntitlementSymbol = dlsym(securityHandle, "SecTaskCopyValueForEntitlement") else {
            return loaderErrorMessage()
        }

        let createTask = unsafeBitCast(createTaskSymbol, to: CreateTaskFunction.self)
        let copyEntitlement = unsafeBitCast(copyEntitlementSymbol, to: CopyEntitlementFunction.self)

        guard let task = createTask(kCFAllocatorDefault)?.takeRetainedValue() else {
            return "SecTaskCreateFromSelf returned nil."
        }

        let keys = [
            "com.apple.developer.family-controls",
            "application-identifier",
            "com.apple.developer.team-identifier"
        ]

        let values = keys.map { key -> String in
            guard let unmanagedValue = copyEntitlement(task, key as CFString, nil) else {
                return "\(key): tidak terbaca"
            }

            let value = unmanagedValue.takeRetainedValue()
            if CFGetTypeID(value) == CFBooleanGetTypeID(), let number = value as? NSNumber {
                return "\(key): \(number.boolValue ? "true" : "false")"
            }
            if let string = value as? String {
                return "\(key): \(string)"
            }
            return "\(key): \(String(reflecting: value))"
        }

        return """
        Runtime entitlements (SecTaskCreateFromSelf):
        \(values.joined(separator: "\n"))
        """
    }

    private static func loaderErrorMessage() -> String {
        guard let message = dlerror() else {
            return "dlerror() returned nil."
        }
        return String(cString: message)
    }
}
