From 5550db6a65feb42a90c58511b846d87a5ca0a4f2 Mon Sep 17 00:00:00 2001
From: Chen Minqiang <ptpt52@gmail.com>
Date: Tue, 16 Jan 2024 17:20:04 +0800
Subject: [PATCH] kernel: ksmbd: only v2 leases handle the directory

This backport a fix for ksmbd. for kernel 5.15.148 and below. 

Refer: https://github.com/namjaejeon/ksmbd/issues/469

Signed-off-by: Chen Minqiang <ptpt52@gmail.com>
---
 ...-only-v2-leases-handle-the-directory.patch | 32 +++++++++++++++++++
 ...-only-v2-leases-handle-the-directory.patch | 32 +++++++++++++++++++
 2 files changed, 64 insertions(+)
 create mode 100644 target/linux/generic/pending-5.15/540-ksmbd-only-v2-leases-handle-the-directory.patch
 create mode 100644 target/linux/generic/pending-6.1/540-ksmbd-only-v2-leases-handle-the-directory.patch

diff --git a/target/linux/generic/pending-5.15/540-ksmbd-only-v2-leases-handle-the-directory.patch b/target/linux/generic/pending-5.15/540-ksmbd-only-v2-leases-handle-the-directory.patch
new file mode 100644
index 0000000000000..1bc0e724188d6
--- /dev/null
+++ b/target/linux/generic/pending-5.15/540-ksmbd-only-v2-leases-handle-the-directory.patch
@@ -0,0 +1,32 @@
+From cb1d41b99e4afa062f904339666fae2578559718 Mon Sep 17 00:00:00 2001
+From: Namjae Jeon <linkinjeon@kernel.org>
+Date: Mon, 15 Jan 2024 10:24:54 +0900
+Subject: [PATCH] ksmbd: only v2 leases handle the directory
+
+When smb2 leases is disable, ksmbd can send oplock break notification
+and cause wait oplock break ack timeout. It may appear like hang when
+accessing a directory. This patch make only v2 leases handle the
+directory.
+
+Cc: stable@vger.kernel.org
+Signed-off-by: Namjae Jeon <linkinjeon@kernel.org>
+Signed-off-by: Steve French <stfrench@microsoft.com>
+---
+ fs/ksmbd/oplock.c | 6 ++++++
+ 1 file changed, 6 insertions(+)
+
+--- a/fs/ksmbd/oplock.c
++++ b/fs/ksmbd/oplock.c
+@@ -1191,6 +1191,12 @@ int smb_grant_oplock(struct ksmbd_work *
+ 	bool prev_op_has_lease;
+ 	__le32 prev_op_state = 0;
+ 
++	/* Only v2 leases handle the directory */
++	if (S_ISDIR(file_inode(fp->filp)->i_mode)) {
++		if (!lctx || lctx->version != 2)
++			return 0;
++	}
++
+ 	opinfo = alloc_opinfo(work, pid, tid);
+ 	if (!opinfo)
+ 		return -ENOMEM;
