diff --git a/target/linux/mediatek/patches-5.15/966-mtk_eth_soc.patch b/target/linux/mediatek/patches-5.15/966-mtk_eth_soc.patch
new file mode 100644
index 0000000..d065233
--- /dev/null
+++ b/target/linux/mediatek/patches-5.15/966-mtk_eth_soc.patch
@@ -0,0 +1,52 @@
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.c b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+index d4c0ea8..0d486e1 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.c
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+@@ -5223,7 +5223,7 @@ static const struct mtk_soc_data mt7621_data = {
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
+-		.dma_size = MTK_DMA_SIZE(2K),
++		.dma_size = MTK_DMA_SIZE(1K),
+ 	},
+ };
+ 
+ static const struct mtk_soc_data mt7622_data = {
+@@ -5326,7 +5326,7 @@ static const struct mtk_soc_data mt7981_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma_v2),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
+-		.dma_size = MTK_DMA_SIZE(2K),
++		.dma_size = MTK_DMA_SIZE(2K),
+ 		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+@@ -5335,7 +5335,7 @@ static const struct mtk_soc_data mt7981_data = {
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
+-		.dma_size = MTK_DMA_SIZE(2K),
++		.dma_size = MTK_DMA_SIZE(512),
+ 	},
+ };
+ 
+ static const struct mtk_soc_data mt7986_data = {
+@@ -5355,7 +5355,7 @@ static const struct mtk_soc_data mt7986_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma_v2),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
+-		.dma_size = MTK_DMA_SIZE(2K),
++		.dma_size = MTK_DMA_SIZE(2K),
+ 		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+@@ -5364,7 +5364,7 @@ static const struct mtk_soc_data mt7986_data = {
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
+-		.dma_size = MTK_DMA_SIZE(2K),
++		.dma_size = MTK_DMA_SIZE(512),
+ 	},
+ };
+ 
+ static const struct mtk_soc_data mt7988_data = {
+-- 
+2.38.1.windows.1
+
-- 
