diff --git a/package/network/utils/speedtest-cli/Makefile b/package/network/utils/speedtest-cli/Makefile
new file mode 100644
--- /dev/null
+++ b/package/network/utils/speedtest-cli/Makefile
@@ -0,0 +1,45 @@
+include $(TOPDIR)/rules.mk
+
+PKG_NAME:=speedtest-cli
+PKG_RELEASE:=1
+PKG_LICNESE:=GPL-2.0+
+PKG_SOURCE_PROTO:=git
+PKG_SOURCE_URL:=https://github.com/rx78gp01/speedtest-cli
+PKG_SOURCE_VERSION:=cc635eefcab33776b66a63e5195488e894fa1f25
+PKG_MIRROR_HASH:=skip
+
+include $(INCLUDE_DIR)/package.mk
+
+define Package/speedtest-cli
+  SECTION:=net
+  CATEGORY:=Network
+  TITLE:=speedtest.net Command line interface
+ifneq ($(CONFIG_USE_MUSL),y)
+  DEPENDS:=+libpthread +libcurl +libexpat +libm
+else
+  DEPENDS:=+libpthread +libcurl +libexpat +libc
+endif
+  MAINTAINER:=Haibo Xi <haibbo@gmail.com>
+endef
+
+define Package/speedtest-cli/description
+  Command line interface for testing internet bandwidth using speedtest.net
+endef
+
+define Build/Configure
+endef
+
+TARGET_LDFLAGS += -lpthread -lcurl -lexpat -lm
+
+define Build/Compile
+	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -Wall \
+		-o $(PKG_BUILD_DIR)/speedtest-cli $(PKG_BUILD_DIR)/main.c $(TARGET_LDFLAGS)
+endef
+
+define Package/speedtest-cli/install
+	$(INSTALL_DIR) $(1)/usr/sbin
+	$(INSTALL_BIN) $(PKG_BUILD_DIR)/speedtest-cli $(1)/usr/sbin/
+endef
+
+$(eval $(call BuildPackage,speedtest-cli))
+
