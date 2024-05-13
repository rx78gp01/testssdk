diff --git a/target/linux/generic/pending-5.15/680-NET-skip-GRO-for-foreign-MAC-addresses.patch b/target/linux/generic/pending-5.15/680-NET-skip-GRO-for-foreign-MAC-addresses.patch
index 66fd6ef..8fc410b 100644
--- a/target/linux/generic/pending-5.15/680-NET-skip-GRO-for-foreign-MAC-addresses.patch
+++ b/target/linux/generic/pending-5.15/680-NET-skip-GRO-for-foreign-MAC-addresses.patch
@@ -115,11 +115,11 @@ Signed-off-by: Felix Fietkau <nbd@nbd.name>
  	call_netdevice_notifiers(NETDEV_CHANGEADDR, dev);
  	add_device_randomness(dev->dev_addr, dev->addr_len);
  	return 0;
---- a/net/ethernet/eth.c
-+++ b/net/ethernet/eth.c
-@@ -142,6 +142,18 @@ u32 eth_get_headlen(const struct net_dev
+--- a/include/linux/etherdevice.h
++++ b/include/linux/etherdevice.h
+@@ -542,6 +542,18 @@ 
+ #endif
  }
- EXPORT_SYMBOL(eth_get_headlen);
  
 +static inline bool
 +eth_check_local_mask(const void *addr1, const void *addr2, const void *mask)
@@ -134,9 +134,9 @@ Signed-off-by: Felix Fietkau <nbd@nbd.name>
 +}
 +
  /**
-  * eth_type_trans - determine the packet's protocol ID.
-  * @skb: received socket data
-@@ -173,6 +185,10 @@ __be16 eth_type_trans(struct sk_buff *sk
+ * eth_skb_pkt_type - Assign packet type if destination address does not match
+ * @skb: Assigned a packet type if address does not match @dev address
+@@ -564,6 +564,10 @@ 
  		} else {
  			skb->pkt_type = PACKET_OTHERHOST;
  		}
@@ -145,5 +145,5 @@ Signed-off-by: Felix Fietkau <nbd@nbd.name>
 +					 dev->local_addr_mask))
 +			skb->gro_skip = 1;
  	}
+ }
  
- 	/*
-- 
2.38.1.windows.1

