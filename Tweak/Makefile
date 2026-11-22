TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := SloopyBlockerTest
SloopyBlockerTest_FILES := Tweak.xm
SloopyBlockerTest_CFLAGS := -fobjc-arc
SloopyBlockerTest_FRAMEWORKS := Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
