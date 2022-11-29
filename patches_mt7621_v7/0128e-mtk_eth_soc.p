diff --git a/target/linux/ramips/patches-5.15/967-mtk_eth_soc.patch b/target/linux/ramips/patches-5.15/967-mtk_eth_soc.patch
new file mode 100644
index 0000000..11c8d17
--- /dev/null
+++ b/target/linux/ramips/patches-5.15/967-mtk_eth_soc.patch
@@ -0,0 +1,39 @@
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.c b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+index 097f291..a52050f 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.c
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+@@ -829,7 +829,7 @@ static void mtk_gdm_mac_link_up(struct mtk_mac *mac,
+ 	mcr = mtk_r32(mac->hw, MTK_MAC_MCR(mac->id));
+ 	mcr &= ~(MAC_MCR_SPEED_100 | MAC_MCR_SPEED_1000 |
+ 		 MAC_MCR_FORCE_DPX | MAC_MCR_FORCE_TX_FC |
+-		 MAC_MCR_FORCE_RX_FC);
++		 MAC_MCR_FORCE_RX_FC | MAC_MCR_PRMBL_LMT_EN);
+ 
+ 	/* Configure speed */
+ 	mac->speed = speed;
+@@ -844,8 +844,9 @@ static void mtk_gdm_mac_link_up(struct mtk_mac *mac,
+ 	}
+ 
+ 	/* Configure duplex */
+-	if (duplex == DUPLEX_FULL)
+ 		mcr |= MAC_MCR_FORCE_DPX;
++		if (duplex == DUPLEX_HALF)
++			mcr |= MAC_MCR_PRMBL_LMT_EN;
+ 
+ 	/* Configure pause modes - phylink will avoid these for half duplex */
+ 	if (tx_pause)
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.h b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+index f988041..4895d6d 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+@@ -450,6 +450,7 @@
+ #define MAC_MCR_TX_EN		BIT(14)
+ #define MAC_MCR_RX_EN		BIT(13)
+ #define MAC_MCR_RX_FIFO_CLR_DIS	BIT(12)
++#define MAC_MCR_PRMBL_LMT_EN	BIT(10)
+ #define MAC_MCR_BACKOFF_EN	BIT(9)
+ #define MAC_MCR_BACKPR_EN	BIT(8)
+ #define MAC_MCR_FORCE_RX_FC	BIT(5)
+-- 
+2.38.1.windows.1
+
-- 
2.38.1.windows.1
