TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SloopyIconFix SloopyIconFixLSD
SloopyIconFix_FILES = Tweak.x
SloopyIconFix_CFLAGS = -fobjc-arc

SloopyIconFixLSD_FILES = LSDTweak.x
SloopyIconFixLSD_CFLAGS = -fobjc-arc -fobjc-exceptions
SloopyIconFixLSD_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
