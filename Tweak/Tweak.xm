#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CydiaSubstrate.h>
#import <dlfcn.h>
#import <time.h>
#import <stdlib.h>
#import <string.h>

static NSString * const kSloopyLogPath = @"/var/mobile/Documents/SloopyBlockerTest.log";
static NSString * const kTrustErrorDomain = @"FBSOpenApplicationErrorDomain";
static const NSInteger kSecurityPolicyErrorCode = 3;
static const double kActiveWindowSeconds = 15.0 * 60.0;

typedef BOOL (*SloopyTrustRequestIMP)(
    id self,
    SEL selector,
    id request,
    id caller,
    id client,
    id bundleInfo,
    id options,
    NSError **fatalError
);

static SloopyTrustRequestIMP gOriginalTrustRequest = NULL;
static struct timespec gSpringBoardStartTime = {0, 0};
static BOOL gHasMonotonicStartTime = NO;
static NSObject *gLogLock = nil;

static const char *SloopySkipTypeQualifiers(const char *type)
{
    if (type == NULL) {
        return NULL;
    }

    while (*type != '\0' && strchr("rnNoORV", *type) != NULL) {
        type++;
    }
    return type;
}

static BOOL SloopyTypeStartsWith(const char *type, char expected)
{
    const char *unqualified = SloopySkipTypeQualifiers(type);
    return unqualified != NULL && unqualified[0] == expected;
}

static BOOL SloopyMethodHasExpectedABI(Method method)
{
    // Mirrors the conservative ABI checks used by AppEnumGuard:
    // 8 Objective-C arguments total; BOOL return; five object parameters;
    // final out-error parameter is a pointer.
    // Reference: https://github.com/kolbicz/AppEnumGuard/blob/main/Tweak/Tweak.mm
    if (method == NULL || method_getNumberOfArguments(method) != 8) {
        return NO;
    }

    char *returnType = method_copyReturnType(method);
    BOOL booleanReturn =
        SloopyTypeStartsWith(returnType, 'B') ||
        SloopyTypeStartsWith(returnType, 'c');
    free(returnType);
    if (!booleanReturn) {
        return NO;
    }

    char *selfType = method_copyArgumentType(method, 0);
    BOOL validSelf = SloopyTypeStartsWith(selfType, '@');
    free(selfType);
    if (!validSelf) {
        return NO;
    }

    char *selectorType = method_copyArgumentType(method, 1);
    BOOL validSelector = SloopyTypeStartsWith(selectorType, ':');
    free(selectorType);
    if (!validSelector) {
        return NO;
    }

    for (unsigned int index = 2; index <= 6; index++) {
        char *argumentType = method_copyArgumentType(method, index);
        BOOL objectArgument = SloopyTypeStartsWith(argumentType, '@');
        free(argumentType);
        if (!objectArgument) {
            return NO;
        }
    }

    char *errorType = method_copyArgumentType(method, 7);
    BOOL pointerArgument = SloopyTypeStartsWith(errorType, '^');
    free(errorType);

    return pointerArgument;
}

static NSString *SloopyBundleIdentifierFromObject(id bundleInfo)
{
    if (bundleInfo == nil || bundleInfo == [NSNull null]) {
        return nil;
    }

    if ([bundleInfo isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)bundleInfo;
        id value = dictionary[@"CFBundleIdentifier"];
        if (![value isKindOfClass:[NSString class]]) {
            value = dictionary[@"bundleIdentifier"];
        }
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            return (NSString *)value;
        }
    }

    /*
     * UNVERIFIED PARAMETER CONTRACT:
     * AppEnumGuard confirms that forBundleInfo: is an object parameter, but
     * its public source does not document the runtime class/accessor contract
     * for iOS 18.2.1. Some LaunchServices/SpringBoard objects expose a
     * bundleIdentifier accessor. We call it only when the actual runtime class
     * advertises a zero-argument object-returning method with that exact name.
     * If this probe cannot establish a string, the hook fails open.
     */
    SEL bundleIdentifierSelector = sel_registerName("bundleIdentifier");
    Class objectClass = object_getClass(bundleInfo);
    Method accessor = objectClass != Nil
        ? class_getInstanceMethod(objectClass, bundleIdentifierSelector)
        : NULL;

    if (accessor != NULL &&
        method_getNumberOfArguments(accessor) == 2) {
        char *returnType = method_copyReturnType(accessor);
        BOOL returnsObject = SloopyTypeStartsWith(returnType, '@');
        free(returnType);

        if (returnsObject) {
            id value = ((id (*)(id, SEL))objc_msgSend)(bundleInfo, bundleIdentifierSelector);
            if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                return (NSString *)value;
            }
        }
    }

    return nil;
}

static BOOL SloopyIsWithinActiveWindow(void)
{
    if (!gHasMonotonicStartTime) {
        return NO;
    }

    struct timespec now = {0, 0};
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        return NO;
    }

    double elapsed = (double)(now.tv_sec - gSpringBoardStartTime.tv_sec) +
        ((double)(now.tv_nsec - gSpringBoardStartTime.tv_nsec) / 1000000000.0);

    return elapsed >= 0.0 && elapsed < kActiveWindowSeconds;
}

static void SloopyLog(NSString *message)
{
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];
    NSLog(@"[SloopyBlockerTest] %@", message);

    @synchronized (gLogLock) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *directory = [kSloopyLogPath stringByDeletingLastPathComponent];

        NSError *directoryError = nil;
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&directoryError];

        if (![fileManager fileExistsAtPath:kSloopyLogPath]) {
            [fileManager createFileAtPath:kSloopyLogPath
                                 contents:nil
                               attributes:nil];
        }

        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:kSloopyLogPath];
        if (handle == nil) {
            NSLog(@"[SloopyBlockerTest] Cannot open log file %@ (directory error: %@)",
                  kSloopyLogPath, directoryError);
            return;
        }

        @try {
            [handle seekToEndOfFile];
            [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        } @catch (NSException *exception) {
            NSLog(@"[SloopyBlockerTest] File logging failed: %@", exception);
            @try {
                [handle closeFile];
            } @catch (__unused NSException *closeException) {
            }
        }
    }
}

static NSSet<NSString *> *SloopyTestBundleIdentifiers(void)
{
    static NSSet<NSString *> *identifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identifiers = [NSSet setWithArray:@[
            @"com.apple.calculator"
        ]];
    });
    return identifiers;
}

static NSSet<NSString *> *SloopyPermanentExclusions(void)
{
    static NSSet<NSString *> *identifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identifiers = [NSSet setWithArray:@[
            @"com.apple.mobilephone",
            @"com.apple.Preferences",
            @"org.coolstar.SileoStore",
            @"com.amywhile.sileo",
            @"org.coolstar.sileo",
            @"com.opa334.Dopamine",
            @"com.opa334.TrollStoreLite",
            @"com.sloopy.daily",
            @"com.apple.springboard"
        ]];
    });
    return identifiers;
}

static BOOL SloopyTrustRequestReplacement(
    id self,
    SEL selector,
    id request,
    id caller,
    id client,
    id bundleInfo,
    id options,
    NSError **fatalError
)
{
    if (gOriginalTrustRequest == NULL) {
        SloopyLog(@"decision=PASS reason=original implementation unavailable");
        return YES;
    }

    if (!SloopyIsWithinActiveWindow()) {
        SloopyLog(@"decision=PASS reason=15-minute test window expired or monotonic clock unavailable");
        return gOriginalTrustRequest(self, selector, request, caller, client,
                                      bundleInfo, options, fatalError);
    }

    NSString *bundleIdentifier = SloopyBundleIdentifierFromObject(bundleInfo);
    if (bundleIdentifier == nil) {
        NSString *className = bundleInfo != nil
            ? NSStringFromClass(object_getClass(bundleInfo))
            : @"(nil)";
        SloopyLog([NSString stringWithFormat:
            @"decision=PASS reason=bundle ID unconfirmed bundleInfoClass=%@", className]);
        return gOriginalTrustRequest(self, selector, request, caller, client,
                                      bundleInfo, options, fatalError);
    }

    if ([SloopyPermanentExclusions() containsObject:bundleIdentifier]) {
        SloopyLog([NSString stringWithFormat:
            @"decision=PASS reason=permanent exclusion bundleID=%@", bundleIdentifier]);
        return gOriginalTrustRequest(self, selector, request, caller, client,
                                      bundleInfo, options, fatalError);
    }

    BOOL isTestTarget = [SloopyTestBundleIdentifiers() containsObject:bundleIdentifier];
    if (!isTestTarget) {
        SloopyLog([NSString stringWithFormat:
            @"decision=PASS reason=not in test list bundleID=%@", bundleIdentifier]);
        return gOriginalTrustRequest(self, selector, request, caller, client,
                                      bundleInfo, options, fatalError);
    }

    if (fatalError == NULL) {
        SloopyLog([NSString stringWithFormat:
            @"decision=PASS reason=fatalError output pointer is null bundleID=%@", bundleIdentifier]);
        return gOriginalTrustRequest(self, selector, request, caller, client,
                                      bundleInfo, options, fatalError);
    }

    /*
     * FBSOpenApplicationErrorDomain and code 3 (security policy) are taken
     * from AppEnumGuard's observed error handling. Whether this exact denial
     * response blocks a Calculator launch on iOS 18.2.1 remains unverified.
     */
    *fatalError = [NSError errorWithDomain:kTrustErrorDomain
                                     code:kSecurityPolicyErrorCode
                                 userInfo:@{
        NSLocalizedDescriptionKey: @"Launch denied by SloopyBlockerTest"
    }];

    SloopyLog([NSString stringWithFormat:
        @"decision=DENY testTarget=YES permanentExclusion=NO bundleID=%@", bundleIdentifier]);
    return NO;
}

__attribute__((constructor))
static void SloopyBlockerTestInitialize(void)
{
    @autoreleasepool {
        gLogLock = [[NSObject alloc] init];

        gHasMonotonicStartTime = (clock_gettime(CLOCK_MONOTONIC, &gSpringBoardStartTime) == 0);
        SloopyLog([NSString stringWithFormat:
            @"constructor started; monotonicStartAvailable=%@ activeWindowSeconds=900",
            gHasMonotonicStartTime ? @"YES" : @"NO"]);

        Class serviceClass = objc_getClass("FBSystemService");
        if (serviceClass == Nil) {
            dlopen("/System/Library/PrivateFrameworks/FrontBoard.framework/FrontBoard",
                   RTLD_NOW | RTLD_LOCAL);
            serviceClass = objc_getClass("FBSystemService");
        }

        if (serviceClass == Nil) {
            SloopyLog(@"hook=NOT_INSTALLED reason=FBSystemService class not found");
            return;
        }

        SEL selector = sel_registerName(
            "_isTrustedRequest:forCaller:fromClient:forBundleInfo:withOptions:fatalError:");
        Method method = class_getInstanceMethod(serviceClass, selector);

        if (method == NULL) {
            SloopyLog(@"hook=NOT_INSTALLED reason=selector not found on FBSystemService");
            return;
        }

        if (!SloopyMethodHasExpectedABI(method)) {
            SloopyLog([NSString stringWithFormat:
                @"hook=NOT_INSTALLED reason=signature mismatch encoding=%s",
                method_getTypeEncoding(method)]);
            return;
        }

        MSHookMessageEx(serviceClass, selector,
                        (IMP)&SloopyTrustRequestReplacement,
                        (IMP *)&gOriginalTrustRequest);

        SloopyLog([NSString stringWithFormat:
            @"hook=REGISTRATION_REQUESTED class=FBSystemService selector=%s encoding=%s",
            sel_getName(selector), method_getTypeEncoding(method)]);
    }
}
