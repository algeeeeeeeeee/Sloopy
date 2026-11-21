#import <Foundation/Foundation.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <unistd.h>

// Small SpringBoard-side loader companion from the IconFix design. It does
// not alter icon rendering. On a respring it checks whether lsd has loaded the
// installed write-side dylib and asks launchd to respawn lsd if it has not.
#define SLOOPY_LSD_DYLIB_PATH "/var/jb/Library/MobileSubstrate/DynamicLibraries/SloopyIconFixLSD.dylib"
#define SLOOPY_LSD_MARKER_PATH "/var/jb/var/mobile/.sloopy_iconfix_lsd_loaded"
#define SLOOPY_LSD_EXEC_PATH "/usr/libexec/lsd"
#define SLOOPY_PROC_ALL_PIDS 1

extern int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize);
extern int proc_pidpath(int pid, void *buffer, uint32_t buffersize);

static pid_t SloopyFindLSD(void) {
    int bytes = proc_listpids(SLOOPY_PROC_ALL_PIDS, 0, NULL, 0);
    if (bytes <= 0) return 0;

    int capacity = bytes + (32 * (int)sizeof(pid_t));
    pid_t *pids = (pid_t *)calloc(1, (size_t)capacity);
    if (!pids) return 0;

    pid_t found = 0;
    int got = proc_listpids(SLOOPY_PROC_ALL_PIDS, 0, pids, capacity);
    if (got > 0) {
        int count = got / (int)sizeof(pid_t);
        char path[4096];
        for (int index = 0; index < count; index++) {
            pid_t pid = pids[index];
            if (pid <= 0) continue;
            path[0] = '\0';
            if (proc_pidpath(pid, path, (uint32_t)sizeof(path)) <= 0) continue;
            if (strcmp(path, SLOOPY_LSD_EXEC_PATH) == 0) {
                found = pid;
                break;
            }
        }
    }

    free(pids);
    return found;
}

static void SloopyEnsureLSDCurrent(void) {
    struct stat installedStat;
    if (stat(SLOOPY_LSD_DYLIB_PATH, &installedStat) != 0) return;

    long long installed = (long long)installedStat.st_mtime;
    long long loaded = -1;

    FILE *marker = fopen(SLOOPY_LSD_MARKER_PATH, "r");
    if (marker) {
        if (fscanf(marker, "%lld", &loaded) != 1) loaded = -1;
        fclose(marker);
    }

    if (loaded == installed) return;

    pid_t lsdPID = SloopyFindLSD();
    if (lsdPID <= 0) {
        NSLog(@"[SloopyIconFix] lsd process not found; loader check will retry next respring");
        return;
    }

    if (kill(lsdPID, SIGTERM) == 0) {
        NSLog(@"[SloopyIconFix] requested launchd to respawn lsd with the installed tweak");
    } else {
        NSLog(@"[SloopyIconFix] could not request lsd restart; check jailbreak logs");
    }
}

%ctor {
    SloopyEnsureLSDCurrent();
}
