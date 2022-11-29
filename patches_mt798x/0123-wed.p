diff --git a/target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi b/target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi
index cb161df81e9d57..c763b4ebb3f57e 100644
--- a/target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi
+++ b/target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi
@@ -450,7 +450,6 @@
 		#address-cells = <1>;
 		#size-cells = <1>;
 		compatible = "mediatek,mt7981-ethsys",
-			     "mediatek,mt7986-ethsys",
 			     "syscon";
 		reg = <0 0x15000000 0 0x1000>;
 		#clock-cells = <1>;
