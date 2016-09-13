GO_EASY_ON_ME = 1
DEBUG = 0
SDKVERSION = 9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MessageTypingIndicators
MessageTypingIndicators_FILES = Tweak.xm
MessageTypingIndicators_PRIVATE_FRAMEWORKS = ChatKit IMCore Preferences

include $(THEOS_MAKE_PATH)/tweak.mk