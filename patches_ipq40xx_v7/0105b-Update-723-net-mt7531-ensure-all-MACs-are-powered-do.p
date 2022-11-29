--- a/target/linux/generic/pending-5.15/723-net-mt7531-ensure-all-MACs-are-powered-down-before-r.patch
+++ b/target/linux/generic/pending-5.15/723-net-mt7531-ensure-all-MACs-are-powered-down-before-r.patch
@@ -15,15 +15,6 @@ Signed-off-by: Alexander Couzens <lynxis@fe80.eu>
 
 --- a/drivers/net/dsa/mt7530.c
 +++ b/drivers/net/dsa/mt7530.c
-@@ -2467,7 +2467,7 @@ mt7531_setup(struct dsa_switch *ds)
- 	struct mt7530_priv *priv = ds->priv;
- 	struct mt7530_dummy_poll p;
- 	u32 val, id;
--	int ret;
-+	int ret, i;
- 
- 	/* Reset whole chip through gpio pin or memory-mapped registers for
- 	 * different type of hardware
 @@ -2499,6 +2499,10 @@ mt7531_setup(struct dsa_switch *ds)
  		return -ENODEV;
  	}
