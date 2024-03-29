From 972280dda4733046aa4cd845ba1f7e35ff3e4709 Mon Sep 17 00:00:00 2001
From: =?UTF-8?q?Old=C5=99ich=20Jedli=C4=8Dka?= <oldium.pro@gmail.com>
Date: Fri, 6 Oct 2023 23:37:47 +0200
Subject: [PATCH] mac80211: fix flush during station removal
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit

The queue flushing during station removal passes AP_VLAN vifs to drivers.
But because those are virtual interfaces and not registered with drivers,
we need to translate them to AP vif first.

Fixes: openwrt#12420
Signed-off-by: Oldřich Jedlička <oldium.pro@gmail.com>
---
 ...-not-pass-AP_VLAN-vif-pointer-to-dri.patch | 56 +++++++++++++++++++
 1 file changed, 56 insertions(+)
 create mode 100644 package/kernel/mac80211/patches/subsys/313-wifi-mac80211-do-not-pass-AP_VLAN-vif-pointer-to-dri.patch

diff --git a/package/kernel/mac80211/patches/subsys/313-wifi-mac80211-do-not-pass-AP_VLAN-vif-pointer-to-dri.patch b/package/kernel/mac80211/patches/subsys/313-wifi-mac80211-do-not-pass-AP_VLAN-vif-pointer-to-dri.patch
new file mode 100644
index 0000000000000..31fd939576c99
--- /dev/null
+++ b/package/kernel/mac80211/patches/subsys/313-wifi-mac80211-do-not-pass-AP_VLAN-vif-pointer-to-dri.patch
@@ -0,0 +1,56 @@
+From d32263526166426b75ed38eb5664a672af195ac2 Mon Sep 17 00:00:00 2001
+From: =?UTF-8?q?Old=C5=99ich=20Jedli=C4=8Dka?= <oldium.pro@gmail.com>
+Date: Fri, 6 Oct 2023 23:07:55 +0200
+Subject: [PATCH] wifi: mac80211: do not pass AP_VLAN vif pointer to drivers
+ during flush
+MIME-Version: 1.0
+Content-Type: text/plain; charset=UTF-8
+Content-Transfer-Encoding: 8bit
+
+This fixes WARN_ONs when using AP_VLANs after station removal. The flush
+call passed AP_VLAN vif to driver, but because these vifs are virtual and
+not registered with drivers, we need to translate to the correct AP vif
+first.
+
+Fixes: 0b75a1b1e42e ("flush queues on STA removal")
+Fixes: d00800a289c9 ("add flush_sta method")
+Signed-off-by: Oldřich Jedlička <oldium.pro@gmail.com>
+---
+ net/mac80211/driver-ops.h | 9 +++++++--
+ 1 file changed, 7 insertions(+), 2 deletions(-)
+
+--- a/net/mac80211/driver-ops.h
++++ b/net/mac80211/driver-ops.h
+@@ -23,7 +23,7 @@
+ static inline struct ieee80211_sub_if_data *
+ get_bss_sdata(struct ieee80211_sub_if_data *sdata)
+ {
+-	if (sdata->vif.type == NL80211_IFTYPE_AP_VLAN)
++	if (sdata && sdata->vif.type == NL80211_IFTYPE_AP_VLAN)
+ 		sdata = container_of(sdata->bss, struct ieee80211_sub_if_data,
+ 				     u.ap);
+ 
+@@ -638,10 +638,13 @@ static inline void drv_flush(struct ieee
+ 			     struct ieee80211_sub_if_data *sdata,
+ 			     u32 queues, bool drop)
+ {
+-	struct ieee80211_vif *vif = sdata ? &sdata->vif : NULL;
++	struct ieee80211_vif *vif;
+ 
+ 	might_sleep();
+ 
++	sdata = get_bss_sdata(sdata);
++	vif = sdata ? &sdata->vif : NULL;
++
+ 	if (sdata && !check_sdata_in_driver(sdata))
+ 		return;
+ 
+@@ -657,6 +660,8 @@ static inline void drv_flush_sta(struct
+ {
+ 	might_sleep();
+ 
++	sdata = get_bss_sdata(sdata);
++
+ 	if (sdata && !check_sdata_in_driver(sdata))
+ 		return;
+ 
