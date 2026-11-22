import CoreFoundation
import Darwin
import FamilyControls
import Foundation

@MainActor
enum SloopyDiagnostics {
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
