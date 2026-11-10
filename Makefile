ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CarPlayHook

CarPlayHook_FILES = Tweak.xm
CarPlayHook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

# Bổ sung dòng này để nhúng entitlements vào tweak khi biên dịch/đóng gói
after-install::
	install.exec "killall -9 SpringBoard"