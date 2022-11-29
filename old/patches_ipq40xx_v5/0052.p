From 9325da80ab5dbd7caf91b2f98117c5f6ae6fc7c2 Mon Sep 17 00:00:00 2001
From: Felix Fietkau <nbd@nbd.name>
Date: Wed, 3 Jan 2024 15:13:32 +0100
Subject: [PATCH] mac80211: fix a race condition related to enabling fast-xmit

fast-xmit must only be enabled after the sta has been uploaded to the driver,
otherwise it could end up passing the not-yet-uploaded sta via drv_tx calls
to the driver, leading to potential crashes because of uninitialized drv_priv
data.
Add a missing sta->uploaded check and re-check fast xmit after inserting a sta.

Signed-off-by: Felix Fietkau <nbd@nbd.name>
(cherry picked from commit 438a97fab69b41387e25cbec45271e7fe159a330)
---
 ...x-race-condition-on-enabling-fast-xm.patch | 34 +++++++++++++++++++
 1 file changed, 34 insertions(+)
 create mode 100644 package/kernel/mac80211/patches/subsys/337-wifi-mac80211-fix-race-condition-on-enabling-fast-xm.patch

diff --git a/package/kernel/mac80211/patches/subsys/337-wifi-mac80211-fix-race-condition-on-enabling-fast-xm.patch b/package/kernel/mac80211/patches/subsys/337-wifi-mac80211-fix-race-condition-on-enabling-fast-xm.patch
new file mode 100644
index 0000000000000..0ef0aa2ef74a1
--- /dev/null
+++ b/package/kernel/mac80211/patches/subsys/337-wifi-mac80211-fix-race-condition-on-enabling-fast-xm.patch
@@ -0,0 +1,34 @@
+From: Felix Fietkau <nbd@nbd.name>
+Date: Wed, 3 Jan 2024 15:10:18 +0100
+Subject: [PATCH] wifi: mac80211: fix race condition on enabling fast-xmit
+
+fast-xmit must only be enabled after the sta has been uploaded to the driver,
+otherwise it could end up passing the not-yet-uploaded sta via drv_tx calls
+to the driver, leading to potential crashes because of uninitialized drv_priv
+data.
+Add a missing sta->uploaded check and re-check fast xmit after inserting a sta.
+
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+
+--- a/net/mac80211/sta_info.c
++++ b/net/mac80211/sta_info.c
+@@ -886,6 +886,7 @@ static int sta_info_insert_finish(struct
+ 
+ 	if (ieee80211_vif_is_mesh(&sdata->vif))
+ 		mesh_accept_plinks_update(sdata);
++	ieee80211_check_fast_xmit(sta);
+ 
+ 	return 0;
+  out_remove:
+--- a/net/mac80211/tx.c
++++ b/net/mac80211/tx.c
+@@ -3041,7 +3041,7 @@ void ieee80211_check_fast_xmit(struct st
+ 	    sdata->vif.type == NL80211_IFTYPE_STATION)
+ 		goto out;
+ 
+-	if (!test_sta_flag(sta, WLAN_STA_AUTHORIZED))
++	if (!test_sta_flag(sta, WLAN_STA_AUTHORIZED) || !sta->uploaded)
+ 		goto out;
+ 
+ 	if (test_sta_flag(sta, WLAN_STA_PS_STA) ||
