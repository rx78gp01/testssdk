diff --git a/package/network/config/firewall4/patches/0001-fw4.patch b/package/network/config/firewall4/patches/0001-fw4.patch
new file mode 100644
index 0000000..db4680c
--- /dev/null
+++ b/package/network/config/firewall4/patches/0001-fw4.patch
@@ -0,0 +1,32 @@
+From 7d57b5da780eccf330acc9eeb4ae38d5fd0d9f47 Mon Sep 17 00:00:00 2001
+From: Andris PE <neandris@gmail.com>
+Date: Fri, 15 Mar 2024 10:49:33 +0200
+Subject: [PATCH] Do not add physical devices for soft offload
+
+Let kernel heuristics take care of offloading decapsulation Packets may still enter flow engine one encapsulation below actual interface subject to heuristics, while exiting it on listed interfaces, in kernel subject to non-flow encapsulation offloads.
+
+Fixes: openwrt/openwrt#13410
+Accidentally-part-fixes: openwrt/openwrt#10224
+
+Signed-off-by: Andris PE <neandris@gmail.com>
+---
+ root/usr/share/ucode/fw4.uc | 6 +++++-
+ 1 file changed, 5 insertions(+), 1 deletion(-)
+
+diff --git a/root/usr/share/ucode/fw4.uc b/root/usr/share/ucode/fw4.uc
+index 551811a..9d60d7a 100644
+--- a/root/usr/share/ucode/fw4.uc
++++ b/root/usr/share/ucode/fw4.uc
+@@ -520,7 +520,11 @@ return {
+ 
+ 		for (let zone in this.zones())
+ 			for (let device in zone.related_physdevs)
+-				push(devices, ...resolve_lower_devices(devstatus, device));
++				if (this.default_option("flow_offloading_hw")) {
++					push(devices, ...resolve_lower_devices(devstatus, device));
++				} else {
++					push(devices,device);
++				}
+ 		devices = sort(uniq(devices));
+ 
+ 		if (this.default_option("flow_offloading_hw")) {
-- 
2.38.1.windows.1
