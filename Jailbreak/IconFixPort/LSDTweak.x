#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/stat.h>

#define SLOOPY_LSD_DYLIB_PATH "/var/jb/Library/MobileSubstrate/DynamicLibraries/SloopyIconFixLSD.dylib"
#define SLOOPY_LSD_MARKER_PATH "/var/jb/var/mobile/.sloopy_iconfix_lsd_loaded"

extern int proc_pidpath(int pid, void *buffer, uint32_t bufferSize);
extern pid_t xpc_connection_get_pid(void *connection);

static NSString *SloopyString(const char *value) {
    return value ? [[NSString alloc] initWithUTF8String:value] : nil;
}

static void SloopyStampLSDLoaded(void) {
    struct stat dylibStat;
    if (stat(SLOOPY_LSD_DYLIB_PATH, &dylibStat) != 0) return;

    FILE *marker = fopen(SLOOPY_LSD_MARKER_PATH, "w");
    if (!marker) return;

    fprintf(marker, "%lld\n", (long long)dylibStat.st_mtime);
    fclose(marker);
}

static pid_t SloopyCallerPID(id client) {
    SEL connectionSelector = sel_registerName("XPCConnection");
    SEL rawConnectionSelector = sel_registerName("_xpcConnection");

    if (!client || ![client respondsToSelector:connectionSelector]) return 0;
    id connection = ((id (*)(id, SEL))objc_msgSend)(client, connectionSelector);
    if (!connection || ![connection respondsToSelector:rawConnectionSelector]) return 0;

    void *rawConnection = ((void *(*)(id, SEL))objc_msgSend)(connection, rawConnectionSelector);
    return rawConnection ? xpc_connection_get_pid(rawConnection) : 0;
}

static NSString *SloopyCallerBundlePath(pid_t pid) {
    if (pid <= 0) return nil;

    char executablePath[4096] = {0};
    if (proc_pidpath(pid, executablePath, (uint32_t)sizeof(executablePath)) <= 0) return nil;

    NSString *executable = SloopyString(executablePath);
    NSString *bundlePath = [executable stringByDeletingLastPathComponent];
    if (![[bundlePath pathExtension] isEqualToString:SloopyString("app")]) return nil;

    return bundlePath;
}

static NSDictionary *SloopyCallerInfo(NSString *bundlePath) {
    if (!bundlePath) return nil;
    NSString *plistPath = [bundlePath stringByAppendingPathComponent:SloopyString("Info.plist")];
    id value = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

static BOOL SloopyManagerMethodIsCompatible(Class managerClass, SEL selector) {
    Method method = class_getInstanceMethod(managerClass, selector);
    if (!method || method_getNumberOfArguments(method) != 6) return NO;

    char *returnType = method_copyReturnType(method);
    BOOL returnsVoid = returnType && returnType[0] == 'v';
    if (returnType) free(returnType);
    if (!returnsVoid) return NO;

    // Expected: self, _cmd, icon name, bundle identifier, icon dictionary, reply block.
    for (unsigned int index = 2; index < 6; index++) {
        char *argumentType = method_copyArgumentType(method, index);
        BOOL isObject = argumentType && argumentType[0] == '@';
        if (argumentType) free(argumentType);
        if (!isObject) return NO;
    }
    return YES;
}

static BOOL SloopyForwardOwnBundleRequest(id client, id name, id identifier, id suppliedIcons, id reply) {
    pid_t callerPID = SloopyCallerPID(client);
    NSDictionary *info = SloopyCallerInfo(SloopyCallerBundlePath(callerPID));

    NSString *ownIdentifier = [info objectForKey:SloopyString("CFBundleIdentifier")];
    if (![ownIdentifier isKindOfClass:[NSString class]] ||
        ![identifier isKindOfClass:[NSString class]] ||
        ![ownIdentifier isEqualToString:identifier]) {
        NSLog(@"[SloopyIconFix] caller ownership did not match; keeping original LaunchServices path");
        return NO;
    }

    // Do not relax cross-app access: the caller's own on-disk bundle must
    // declare exactly the identifier the request asks LaunchServices to edit.
    NSDictionary *diskIcons = [info objectForKey:SloopyString("CFBundleIcons")];
    id iconsToUse = [diskIcons isKindOfClass:[NSDictionary class]] ? diskIcons : suppliedIcons;

    Class managerClass = objc_getClass("LSAltIconManager");
    SEL setterSelector = sel_registerName("setAlternateIconName:forIdentifier:iconsDictionary:reply:");
    if (!managerClass || !SloopyManagerMethodIsCompatible(managerClass, setterSelector)) {
        NSLog(@"[SloopyIconFix] LSAltIconManager method unavailable or changed; keeping original path");
        return NO;
    }

    SEL sharedSelector = sel_registerName("sharedInstance");
    if (![managerClass respondsToSelector:sharedSelector]) {
        NSLog(@"[SloopyIconFix] LSAltIconManager singleton unavailable; keeping original path");
        return NO;
    }

    id manager = ((id (*)(id, SEL))objc_msgSend)((id)managerClass, sharedSelector);
    if (!manager) return NO;

    ((void (*)(id, SEL, id, id, id, id))objc_msgSend)(
        manager, setterSelector, name, identifier, iconsToUse, reply
    );

    NSLog(@"[SloopyIconFix] verified caller bundle and forwarded alternate icon request");
    return YES;
}

%hook _LSDIconClient

- (void)setAlternateIconName:(id)name
               forIdentifier:(id)identifier
             iconsDictionary:(id)iconsDictionary
                       reply:(id)reply {
    BOOL handled = NO;
    @try {
        handled = SloopyForwardOwnBundleRequest(self, name, identifier, iconsDictionary, reply);
    } @catch (NSException *exception) {
        NSLog(@"[SloopyIconFix] guarded exception %@; keeping original path", exception.name);
        handled = NO;
    }

    if (!handled) %orig;
}

%end

%ctor {
    if (objc_getClass("_LSDIconClient")) {
        %init;
        SloopyStampLSDLoaded();
        NSLog(@"[SloopyIconFix] write-path hook loaded in lsd");
    } else {
        NSLog(@"[SloopyIconFix] _LSDIconClient not found; hook not installed");
    }
}
