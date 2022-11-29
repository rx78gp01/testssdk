diff --git a/package/utils/xinfc/Makefile b/package/utils/xinfc/Makefile
new file mode 100644
--- /dev/null
+++ b/package/utils/xinfc/Makefile
@@ -0,0 +1,43 @@
+include $(TOPDIR)/rules.mk
+
+PKG_NAME:=xinfc
+PKG_VERSION:=1
+PKG_RELEASE:=1
+
+PKG_LICNESE:=GPL-2.0+
+PKG_SOURCE_PROTO:=git
+PKG_SOURCE_URL:=https://github.com/Caian/xinfc
+PKG_SOURCE_VERSION:=96cc19fa4e8c30403063ac3a1be040b842ff5869
+PKG_MIRROR_HASH:=skip
+
+include $(INCLUDE_DIR)/package.mk
+
+define Package/xinfc
+  SECTION:=utils
+  CATEGORY:=Utilities
+  TITLE:=Tools for interfacing with the NFC chip on Xiaomi routers
+  DEPENDS:=+libstdcpp +kmod-i2c-gpio +i2c-tools
+  MAINTAINER:=Caian Benedicto <caianbene@gmail.com>
+endef
+
+define Package/xinfc/description
+  Command line tools for interfacing with the NFC chip on Xiaomi routers
+endef
+
+define Build/Configure
+endef
+
+TARGET_LDFLAGS +=
+
+define Build/Compile
+	$(TARGET_CXX) $(TARGET_CXXFLAGS) -Wall \
+		-o $(PKG_BUILD_DIR)/xinfc-wsc $(PKG_BUILD_DIR)/src/xinfc-wsc.cpp -Iinclude
+endef
+
+define Package/xinfc/install
+	$(INSTALL_DIR) $(1)/usr/sbin
+	$(INSTALL_BIN) $(PKG_BUILD_DIR)/xinfc-wsc $(1)/usr/sbin/
+endef
+
+$(eval $(call BuildPackage,xinfc))
+
