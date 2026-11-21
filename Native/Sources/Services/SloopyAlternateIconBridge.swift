import Foundation
import UIKit
import ObjectiveC.runtime

/// Uses LaunchServices' current-process bundle proxy before falling back to
/// UIApplication's public alternate-icon API. This is useful for environments
/// where the public UIApplication route is rejected for re-signed app bundles.
enum SloopyAlternateIconBridge {
    private typealias ResultBlock = @convention(block) (Bool, AnyObject?) -> Void
    private typealias ProxyGetter = @convention(c) (AnyClass, Selector) -> AnyObject?
    private typealias ProxySetter = @convention(c) (AnyObject, Selector, NSString?, ResultBlock) -> Void

    static func setAlternateIconName(
        _ iconName: String?,
        completion: @escaping (_ route: String, _ error: NSError?) -> Void
    ) {
        let proxyClassName = "LSBundleProxy"
        let getterSelector = NSSelectorFromString("bundleProxyForCurrentProcess")
        let setterSelector = NSSelectorFromString("setAlternateIconName:withResult:")

        guard
            let proxyClass = NSClassFromString(proxyClassName),
            let getterMethod = class_getClassMethod(proxyClass, getterSelector)
        else {
            setUsingUIKit(iconName, route: "UIApplication fallback", previousError: nil, completion: completion)
            return
        }

        let getter = unsafeBitCast(method_getImplementation(getterMethod), to: ProxyGetter.self)
        guard
            let proxy = getter(proxyClass, getterSelector),
            let setterMethod = class_getInstanceMethod(type(of: proxy), setterSelector)
        else {
            setUsingUIKit(iconName, route: "UIApplication fallback", previousError: nil, completion: completion)
            return
        }

        let setter = unsafeBitCast(method_getImplementation(setterMethod), to: ProxySetter.self)
        let result: ResultBlock = { succeeded, rawError in
            DispatchQueue.main.async {
                let proxyError = rawError as? NSError
                if succeeded && proxyError == nil {
                    completion("LSBundleProxy", nil)
                    return
                }

                let failure = proxyError ?? NSError(
                    domain: "SloopyAlternateIconBridge",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "LSBundleProxy rejected the alternate icon request."]
                )
                setUsingUIKit(
                    iconName,
                    route: "UIApplication fallback",
                    previousError: failure,
                    completion: completion
                )
            }
        }

        setter(proxy, setterSelector, iconName as NSString?, result)
    }

    private static func setUsingUIKit(
        _ iconName: String?,
        route: String,
        previousError: NSError?,
        completion: @escaping (_ route: String, _ error: NSError?) -> Void
    ) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
                guard let error = error as NSError? else {
                    completion(route, nil)
                    return
                }

                guard let previousError else {
                    completion(route, error)
                    return
                }

                var details = error.userInfo
                details["SloopyLSBundleProxyErrorDomain"] = previousError.domain
                details["SloopyLSBundleProxyErrorCode"] = previousError.code
                details["SloopyLSBundleProxyErrorDescription"] = previousError.localizedDescription
                completion(route, NSError(domain: error.domain, code: error.code, userInfo: details))
            }
        }
    }
}
