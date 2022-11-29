diff --git a/target/linux/mediatek/patches-5.15/964-mtk-soc.patch b/target/linux/mediatek/patches-5.15/964-mtk-soc.patch
new file mode 100644
index 0000000..e3f45e5
--- /dev/null
+++ b/target/linux/mediatek/patches-5.15/964-mtk-soc.patch
@@ -0,0 +1,341 @@
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.c b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+index e7b9911..a8256c0 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.c
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+@@ -1231,9 +1231,9 @@ static int mtk_init_fq_dma(struct mtk_eth *eth)
+ {
+ 	const struct mtk_soc_data *soc = eth->soc;
+ 	dma_addr_t phy_ring_tail;
+-	int cnt = MTK_QDMA_RING_SIZE;
++	int cnt = soc->tx.fq_dma_size;
+ 	dma_addr_t dma_addr;
+-	int i;
++	int i, j, len;
+ 
+ 	if (MTK_HAS_CAPS(eth->soc->caps, MTK_SRAM))
+ 		eth->scratch_ring = eth->sram_base;
+@@ -1242,37 +1242,47 @@ static int mtk_init_fq_dma(struct mtk_eth *eth)
+ 						       cnt * soc->tx.desc_size,
+ 						       &eth->phy_scratch_ring,
+ 						       GFP_KERNEL);
++
+ 	if (unlikely(!eth->scratch_ring))
+ 		return -ENOMEM;
+ 
+-	eth->scratch_head = kcalloc(cnt, MTK_QDMA_PAGE_SIZE, GFP_KERNEL);
+-	if (unlikely(!eth->scratch_head))
+-		return -ENOMEM;
++	phy_ring_tail = eth->phy_scratch_ring + soc->tx.desc_size * (cnt - 1);
+ 
+-	dma_addr = dma_map_single(eth->dma_dev,
+-				  eth->scratch_head, cnt * MTK_QDMA_PAGE_SIZE,
+-				  DMA_FROM_DEVICE);
+-	if (unlikely(dma_mapping_error(eth->dma_dev, dma_addr)))
+-		return -ENOMEM;
++	for (j = 0; j < DIV_ROUND_UP(soc->tx.fq_dma_size, MTK_FQ_DMA_LENGTH); j++) {
++		len = min_t(int, cnt - j * MTK_FQ_DMA_LENGTH, MTK_FQ_DMA_LENGTH);
++		eth->scratch_head[j] = kcalloc(len, MTK_QDMA_PAGE_SIZE, GFP_KERNEL);
+ 
+-	phy_ring_tail = eth->phy_scratch_ring + soc->tx.desc_size * (cnt - 1);
++		if (unlikely(!eth->scratch_head[j]))
++			return -ENOMEM;
+ 
+-	for (i = 0; i < cnt; i++) {
+-		struct mtk_tx_dma_v2 *txd;
++		dma_addr = dma_map_single(eth->dma_dev,
++					  eth->scratch_head[j], len * MTK_QDMA_PAGE_SIZE,
++					  DMA_FROM_DEVICE);
+ 
+-		txd = eth->scratch_ring + i * soc->tx.desc_size;
+-		txd->txd1 = dma_addr + i * MTK_QDMA_PAGE_SIZE;
+-		if (i < cnt - 1)
+-			txd->txd2 = eth->phy_scratch_ring +
+-				    (i + 1) * soc->tx.desc_size;
++		if (unlikely(dma_mapping_error(eth->dma_dev, dma_addr)))
++			return -ENOMEM;
+ 
+-		txd->txd3 = TX_DMA_PLEN0(MTK_QDMA_PAGE_SIZE);
+-		txd->txd4 = 0;
+-		if (mtk_is_netsys_v2_or_greater(eth)) {
+-			txd->txd5 = 0;
+-			txd->txd6 = 0;
+-			txd->txd7 = 0;
+-			txd->txd8 = 0;
++		for (i = 0; i < len; i++) {
++			struct mtk_tx_dma_v2 *txd;
++
++			txd = eth->scratch_ring + (j * MTK_FQ_DMA_LENGTH + i) * soc->tx.desc_size;
++			txd->txd1 = dma_addr + i * MTK_QDMA_PAGE_SIZE;
++			if (j * MTK_FQ_DMA_LENGTH + i < cnt)
++				txd->txd2 = eth->phy_scratch_ring +
++					    (j * MTK_FQ_DMA_LENGTH + i + 1) * soc->tx.desc_size;
++
++			txd->txd3 = TX_DMA_PLEN0(MTK_QDMA_PAGE_SIZE);
++
++			if (MTK_HAS_CAPS(soc->caps, MTK_36BIT_DMA))
++				txd->txd3 |= TX_DMA_PREP_ADDR64(dma_addr + i * MTK_QDMA_PAGE_SIZE);
++
++			txd->txd4 = 0;
++			if (mtk_is_netsys_v2_or_greater(eth)) {
++				txd->txd5 = 0;
++				txd->txd6 = 0;
++				txd->txd7 = 0;
++				txd->txd8 = 0;
++			}
+ 		}
+ 	}
+ 
+@@ -2577,7 +2588,7 @@ static int mtk_tx_alloc(struct mtk_eth *eth)
+ 	if (MTK_HAS_CAPS(soc->caps, MTK_QDMA))
+ 		ring_size = MTK_QDMA_RING_SIZE;
+ 	else
+-		ring_size = MTK_DMA_SIZE;
++		ring_size = soc->tx.dma_size;
+ 
+ 	ring->buf = kcalloc(ring_size, sizeof(*ring->buf),
+ 			       GFP_KERNEL);
+@@ -2585,8 +2596,8 @@ static int mtk_tx_alloc(struct mtk_eth *eth)
+ 		goto no_tx_mem;
+ 
+ 	if (MTK_HAS_CAPS(soc->caps, MTK_SRAM)) {
+-		ring->dma = eth->sram_base + ring_size * sz;
+-		ring->phys = eth->phy_scratch_ring + ring_size * (dma_addr_t)sz;
++		ring->dma = eth->sram_base + soc->tx.fq_dma_size * sz;
++		ring->phys = eth->phy_scratch_ring + soc->tx.fq_dma_size * (dma_addr_t)sz;
+ 	} else {
+ 		ring->dma = dma_alloc_coherent(eth->dma_dev, ring_size * sz,
+ 					       &ring->phys, GFP_KERNEL);
+@@ -2708,6 +2719,7 @@ static void mtk_tx_clean(struct mtk_eth *eth)
+ static int mtk_rx_alloc(struct mtk_eth *eth, int ring_no, int rx_flag)
+ {
+ 	const struct mtk_reg_map *reg_map = eth->soc->reg_map;
++	const struct mtk_soc_data *soc = eth->soc;
+ 	struct mtk_rx_ring *ring;
+ 	int rx_data_len, rx_dma_size, tx_ring_size;
+ 	int i;
+@@ -2715,7 +2727,7 @@ static int mtk_rx_alloc(struct mtk_eth *eth, int ring_no, int rx_flag)
+ 	if (MTK_HAS_CAPS(eth->soc->caps, MTK_QDMA))
+ 		tx_ring_size = MTK_QDMA_RING_SIZE;
+ 	else
+-		tx_ring_size = MTK_DMA_SIZE;
++		tx_ring_size = soc->tx.dma_size;
+ 
+ 	if (rx_flag == MTK_RX_FLAGS_QDMA) {
+ 		if (ring_no)
+@@ -2730,7 +2742,7 @@ static int mtk_rx_alloc(struct mtk_eth *eth, int ring_no, int rx_flag)
+ 		rx_dma_size = MTK_HW_LRO_DMA_SIZE;
+ 	} else {
+ 		rx_data_len = ETH_DATA_LEN;
+-		rx_dma_size = MTK_DMA_SIZE;
++		rx_dma_size = soc->rx.dma_size;
+ 	}
+ 
+ 	ring->frag_size = mtk_max_frag_size(rx_data_len);
+@@ -3257,7 +3269,10 @@ static void mtk_dma_free(struct mtk_eth *eth)
+ 			mtk_rx_clean(eth, &eth->rx_ring[i], false);
+ 	}
+ 
+-	kfree(eth->scratch_head);
++	for (i = 0; i < DIV_ROUND_UP(soc->tx.fq_dma_size, MTK_FQ_DMA_LENGTH); i++) {
++		kfree(eth->scratch_head[i]);
++		eth->scratch_head[i] = NULL;
++	}
+ }
+ 
+ static bool mtk_hw_reset_check(struct mtk_eth *eth)
+@@ -5171,6 +5186,8 @@ static const struct mtk_soc_data mt2701_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5178,6 +5195,7 @@ static const struct mtk_soc_data mt2701_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5195,6 +5213,8 @@ static const struct mtk_soc_data mt7621_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5202,6 +5222,7 @@ static const struct mtk_soc_data mt7621_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5221,6 +5242,8 @@ static const struct mtk_soc_data mt7622_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5228,6 +5251,7 @@ static const struct mtk_soc_data mt7622_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5246,6 +5270,8 @@ static const struct mtk_soc_data mt7623_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5253,6 +5279,7 @@ static const struct mtk_soc_data mt7623_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5269,6 +5296,8 @@ static const struct mtk_soc_data mt7629_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5276,6 +5305,7 @@ static const struct mtk_soc_data mt7629_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5295,6 +5325,8 @@ static const struct mtk_soc_data mt7981_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma_v2),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5302,6 +5334,7 @@ static const struct mtk_soc_data mt7981_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID_V2,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5321,6 +5354,8 @@ static const struct mtk_soc_data mt7986_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma_v2),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5328,6 +5363,7 @@ static const struct mtk_soc_data mt7986_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID_V2,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5347,6 +5383,8 @@ static const struct mtk_soc_data mt7988_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma_v2),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
++		.dma_size = MTK_DMA_SIZE(2K),
++		.fq_dma_size = MTK_DMA_SIZE(4K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma_v2),
+@@ -5354,6 +5392,7 @@ static const struct mtk_soc_data mt7988_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID_V2,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN_V2,
+ 		.dma_len_offset = 8,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+@@ -5368,6 +5407,7 @@ static const struct mtk_soc_data rt5350_data = {
+ 		.desc_size = sizeof(struct mtk_tx_dma),
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ 	.rx = {
+ 		.desc_size = sizeof(struct mtk_rx_dma),
+@@ -5375,6 +5415,7 @@ static const struct mtk_soc_data rt5350_data = {
+ 		.dma_l4_valid = RX_DMA_L4_VALID_PDMA,
+ 		.dma_max_len = MTK_TX_DMA_BUF_LEN,
+ 		.dma_len_offset = 16,
++		.dma_size = MTK_DMA_SIZE(2K),
+ 	},
+ };
+ 
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.h b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+index 115c1d2..f988041 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+@@ -32,7 +32,9 @@
+ #define MTK_TX_DMA_BUF_LEN	0x3fff
+ #define MTK_TX_DMA_BUF_LEN_V2	0xffff
+ #define MTK_QDMA_RING_SIZE	2048
+-#define MTK_DMA_SIZE		512
++#define MTK_DMA_SIZE(x)	(SZ_##x)
++#define MTK_FQ_DMA_HEAD	32
++#define MTK_FQ_DMA_LENGTH	256
+ #define MTK_RX_ETH_HLEN		(VLAN_ETH_HLEN + ETH_FCS_LEN)
+ #define MTK_RX_HLEN		(NET_SKB_PAD + MTK_RX_ETH_HLEN + NET_IP_ALIGN)
+ #define MTK_DMA_DUMMY_DESC	0xffffffff
+@@ -1302,6 +1304,8 @@ struct mtk_soc_data {
+ 		u32	desc_size;
+ 		u32	dma_max_len;
+ 		u32	dma_len_offset;
++		u32	dma_size;
++		u32	fq_dma_size;
+ 	} tx;
+ 	struct {
+ 		u32	desc_size;
+@@ -1309,6 +1313,7 @@ struct mtk_soc_data {
+ 		u32	dma_l4_valid;
+ 		u32	dma_max_len;
+ 		u32	dma_len_offset;
++		u32	dma_size;
+ 	} rx;
+ };
+ 
+@@ -1418,7 +1423,7 @@ struct mtk_eth {
+ 	struct napi_struct		rx_napi;
+ 	void				*scratch_ring;
+ 	dma_addr_t			phy_scratch_ring;
+-	void				*scratch_head;
++	void				*scratch_head[MTK_FQ_DMA_HEAD];
+ 	struct clk			*clks[MTK_CLK_MAX];
+ 
+ 	struct mii_bus			*mii_bus;
+-- 
+2.38.1.windows.1
+
-- 
2.38.1.windows.1

