diff --git a/package/libs/openssl/patches/9001.patch b/package/libs/openssl/patches/9001.patch
new file mode 100644
index 0000000..d5778d3
--- /dev/null
+++ b/package/libs/openssl/patches/9001.patch
@@ -0,0 +1,63 @@
+From 4ee81ec4e0c2842d9ec1549a83516000b4685a4d Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Fri, 26 Jan 2024 11:33:18 -0500
+Subject: [PATCH] fix missing null check in kdf_test_ctrl
+
+Coverity issue 1453632 noted a missing null check in kdf_test_ctrl
+recently.  If a malformed value is passed in from the test file that
+does not contain a ':' character, the p variable will be NULL, leading
+to a NULL derefence prepare_from_text
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23398)
+
+(cherry picked from commit 6ca1d3ee81b61bc973e4e1079ec68ac73331c159)
+---
+ test/evp_test.c | 15 +++++++++------
+ 1 file changed, 9 insertions(+), 6 deletions(-)
+
+diff --git a/test/evp_test.c b/test/evp_test.c
+index 782841a69258b..2701040dabe7f 100644
+--- a/test/evp_test.c
++++ b/test/evp_test.c
+@@ -2773,30 +2773,33 @@ static int kdf_test_ctrl(EVP_TEST *t, EVP_KDF_CTX *kctx,
+     if (!TEST_ptr(name = OPENSSL_strdup(value)))
+         return 0;
+     p = strchr(name, ':');
+-    if (p != NULL)
++    if (p == NULL)
++        p = "";
++    else
+         *p++ = '\0';
+ 
+     rv = OSSL_PARAM_allocate_from_text(kdata->p, defs, name, p,
+-                                       p != NULL ? strlen(p) : 0, NULL);
++                                       strlen(p), NULL);
+     *++kdata->p = OSSL_PARAM_construct_end();
+     if (!rv) {
+         t->err = "KDF_PARAM_ERROR";
+         OPENSSL_free(name);
+         return 0;
+     }
+-    if (p != NULL && strcmp(name, "digest") == 0) {
++    if (strcmp(name, "digest") == 0) {
+         if (is_digest_disabled(p)) {
+             TEST_info("skipping, '%s' is disabled", p);
+             t->skip = 1;
+         }
+     }
+-    if (p != NULL
+-        && (strcmp(name, "cipher") == 0
+-            || strcmp(name, "cekalg") == 0)
++
++    if ((strcmp(name, "cipher") == 0
++        || strcmp(name, "cekalg") == 0)
+         && is_cipher_disabled(p)) {
+         TEST_info("skipping, '%s' is disabled", p);
+         t->skip = 1;
+     }
++
+     OPENSSL_free(name);
+     return 1;
+ }
diff --git a/package/libs/openssl/patches/9002.patch b/package/libs/openssl/patches/9002.patch
new file mode 100644
index 0000000..087ad1d
--- /dev/null
+++ b/package/libs/openssl/patches/9002.patch
@@ -0,0 +1,43 @@
+From 25681cb8dcc3086c681917926fe8199df14bf83e Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Sun, 28 Jan 2024 23:50:16 +0100
+Subject: [PATCH] Fix a possible memleak in bind_afalg
+
+bind_afalg calls afalg_aes_cbc which allocates
+cipher_handle->_hidden global object(s)
+but if one of them fails due to out of memory,
+the function bind_afalg relies on the engine destroy
+method to be called.  But that does not happen
+because the dynamic engine object is not destroyed
+in the usual way in dynamic_load in this case:
+
+If the bind_engine function fails, there will be no
+further calls into the shared object.
+See ./crypto/engine/eng_dyn.c near the comment:
+/* Copy the original ENGINE structure back */
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23409)
+
+(cherry picked from commit 729a1496cc4cda669dea6501c991113c78f04560)
+---
+ engines/e_afalg.c | 4 +++-
+ 1 file changed, 3 insertions(+), 1 deletion(-)
+
+diff --git a/engines/e_afalg.c b/engines/e_afalg.c
+index 2c08cbb28dde3..ccef155ea293c 100644
+--- a/engines/e_afalg.c
++++ b/engines/e_afalg.c
+@@ -811,8 +811,10 @@ static int bind_helper(ENGINE *e, const char *id)
+     if (!afalg_chk_platform())
+         return 0;
+ 
+-    if (!bind_afalg(e))
++    if (!bind_afalg(e)) {
++        afalg_destroy(e);
+         return 0;
++    }
+     return 1;
+ }
+ 
diff --git a/package/libs/openssl/patches/9003.patch b/package/libs/openssl/patches/9003.patch
new file mode 100644
index 0000000..4378238
--- /dev/null
+++ b/package/libs/openssl/patches/9003.patch
@@ -0,0 +1,113 @@
+From 5781c0a181c97530e57708fa67bb5faa44368246 Mon Sep 17 00:00:00 2001
+From: Richard Levitte <levitte@openssl.org>
+Date: Mon, 29 Jan 2024 08:51:52 +0100
+Subject: [PATCH] Fix error reporting in EVP_PKEY_{sign,verify,verify_recover}
+
+For some reason, those functions (and the _init functions too) would
+raise EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE when the passed
+ctx is NULL, and then not check if the provider supplied the function
+that would support these libcrypto functions.
+
+This corrects the situation, and has all those libcrypto functions
+raise ERR_R_PASS_NULL_PARAMETER if ctx is NULL, and then check for the
+corresponding provider supplied, and only when that one is missing,
+raise EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE.
+
+Because 0 doesn't mean error for EVP_PKEY_verify(), -1 is returned when
+ERR_R_PASSED_NULL_PARAMETER is raised.  This is done consistently for all
+affected functions.
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23411)
+
+(cherry picked from commit 5a25177d1b07ef6e754fec1747b57ee90ab1e028)
+---
+ crypto/evp/signature.c | 31 +++++++++++++++++++++++--------
+ 1 file changed, 23 insertions(+), 8 deletions(-)
+
+diff --git a/crypto/evp/signature.c b/crypto/evp/signature.c
+index fb269b3bfd071..56895055661c9 100644
+--- a/crypto/evp/signature.c
++++ b/crypto/evp/signature.c
+@@ -403,8 +403,8 @@ static int evp_pkey_signature_init(EVP_PKEY_CTX *ctx, int operation,
+     int iter;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     evp_pkey_ctx_free_old_ops(ctx);
+@@ -634,8 +634,8 @@ int EVP_PKEY_sign(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_SIGN) {
+@@ -646,6 +646,11 @@ int EVP_PKEY_sign(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->sign == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->sign(ctx->op.sig.algctx, sig, siglen,
+                                       (sig == NULL) ? 0 : *siglen, tbs, tbslen);
+ 
+@@ -678,8 +683,8 @@ int EVP_PKEY_verify(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_VERIFY) {
+@@ -690,6 +695,11 @@ int EVP_PKEY_verify(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->verify == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->verify(ctx->op.sig.algctx, sig, siglen,
+                                         tbs, tbslen);
+ 
+@@ -721,8 +731,8 @@ int EVP_PKEY_verify_recover(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_VERIFYRECOVER) {
+@@ -733,6 +743,11 @@ int EVP_PKEY_verify_recover(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->verify_recover == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->verify_recover(ctx->op.sig.algctx, rout,
+                                                 routlen,
+                                                 (rout == NULL ? 0 : *routlen),
diff --git a/package/libs/openssl/patches/9004.patch b/package/libs/openssl/patches/9004.patch
new file mode 100644
index 0000000..50efa21
--- /dev/null
+++ b/package/libs/openssl/patches/9004.patch
@@ -0,0 +1,79 @@
+From ad6cbe4b7f57a783a66a7ae883ea0d35ef5f82b6 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 15 Dec 2023 13:45:50 +0100
+Subject: [PATCH] Revert "Improved detection of engine-provided private
+ "classic" keys"
+
+This reverts commit 2b74e75331a27fc89cad9c8ea6a26c70019300b5.
+
+The commit was wrong. With 3.x versions the engines must be themselves
+responsible for creating their EVP_PKEYs in a way that they are treated
+as legacy - either by using the respective set1 calls or by setting
+non-default EVP_PKEY_METHOD.
+
+The workaround has caused more problems than it solved.
+
+Fixes #22945
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23063)
+
+(cherry picked from commit 39ea78379826fa98e8dc8c0d2b07e2c17cd68380)
+---
+ crypto/engine/eng_pkey.c | 42 ----------------------------------------
+ 1 file changed, 42 deletions(-)
+
+diff --git a/crypto/engine/eng_pkey.c b/crypto/engine/eng_pkey.c
+index f84fcde460162..075a61b5bfbf8 100644
+--- a/crypto/engine/eng_pkey.c
++++ b/crypto/engine/eng_pkey.c
+@@ -79,48 +79,6 @@ EVP_PKEY *ENGINE_load_private_key(ENGINE *e, const char *key_id,
+         ERR_raise(ERR_LIB_ENGINE, ENGINE_R_FAILED_LOADING_PRIVATE_KEY);
+         return NULL;
+     }
+-    /* We enforce check for legacy key */
+-    switch (EVP_PKEY_get_id(pkey)) {
+-    case EVP_PKEY_RSA:
+-        {
+-        RSA *rsa = EVP_PKEY_get1_RSA(pkey);
+-        EVP_PKEY_set1_RSA(pkey, rsa);
+-        RSA_free(rsa);
+-        }
+-        break;
+-#  ifndef OPENSSL_NO_EC
+-    case EVP_PKEY_SM2:
+-    case EVP_PKEY_EC:
+-        {
+-        EC_KEY *ec = EVP_PKEY_get1_EC_KEY(pkey);
+-        EVP_PKEY_set1_EC_KEY(pkey, ec);
+-        EC_KEY_free(ec);
+-        }
+-        break;
+-#  endif
+-#  ifndef OPENSSL_NO_DSA
+-    case EVP_PKEY_DSA:
+-        {
+-        DSA *dsa = EVP_PKEY_get1_DSA(pkey);
+-        EVP_PKEY_set1_DSA(pkey, dsa);
+-        DSA_free(dsa);
+-        }
+-        break;
+-#endif
+-#  ifndef OPENSSL_NO_DH
+-    case EVP_PKEY_DH:
+-        {
+-        DH *dh = EVP_PKEY_get1_DH(pkey);
+-        EVP_PKEY_set1_DH(pkey, dh);
+-        DH_free(dh);
+-        }
+-        break;
+-#endif
+-    default:
+-        /*Do nothing */
+-        break;
+-    }
+-
+     return pkey;
+ }
+ 
diff --git a/package/libs/openssl/patches/9005.patch b/package/libs/openssl/patches/9005.patch
new file mode 100644
index 0000000..01b050f
--- /dev/null
+++ b/package/libs/openssl/patches/9005.patch
@@ -0,0 +1,64 @@
+From 7b3eda56d7891aceef91867de64f24b20e3db212 Mon Sep 17 00:00:00 2001
+From: Richard Levitte <levitte@openssl.org>
+Date: Thu, 1 Feb 2024 10:57:51 +0100
+Subject: [PATCH] Fix a few incorrect paths in some build.info files
+
+The following files referred to ../liblegacy.a when they should have
+referred to ../../liblegacy.a.  This cause the creation of a mysterious
+directory 'crypto/providers', and because of an increased strictness
+with regards to where directories are created, configuration failure
+on some platforms.
+
+Fixes #23436
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23452)
+
+(cherry picked from commit 667b45454a47959ce2934b74c899662e686993de)
+---
+ crypto/aes/build.info | 2 +-
+ crypto/ec/build.info  | 2 +-
+ crypto/sha/build.info | 2 +-
+ 3 files changed, 3 insertions(+), 3 deletions(-)
+
+diff --git a/crypto/aes/build.info b/crypto/aes/build.info
+index b250903fa6e26..271015e35e1bb 100644
+--- a/crypto/aes/build.info
++++ b/crypto/aes/build.info
+@@ -76,7 +76,7 @@ DEFINE[../../providers/libdefault.a]=$AESDEF
+ # already gets everything that the static libcrypto.a has, and doesn't need it
+ # added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$AESDEF
++  DEFINE[../../providers/liblegacy.a]=$AESDEF
+ ENDIF
+ 
+ GENERATE[aes-ia64.s]=asm/aes-ia64.S
+diff --git a/crypto/ec/build.info b/crypto/ec/build.info
+index a511e887a9ba1..6dd98e9f4f172 100644
+--- a/crypto/ec/build.info
++++ b/crypto/ec/build.info
+@@ -77,7 +77,7 @@ DEFINE[../../providers/libdefault.a]=$ECDEF
+ # Otherwise, it already gets everything that the static libcrypto.a
+ # has, and doesn't need it added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$ECDEF
++  DEFINE[../../providers/liblegacy.a]=$ECDEF
+ ENDIF
+ 
+ GENERATE[ecp_nistz256-x86.S]=asm/ecp_nistz256-x86.pl
+diff --git a/crypto/sha/build.info b/crypto/sha/build.info
+index d61f7de9b6bde..186ec13cc82a1 100644
+--- a/crypto/sha/build.info
++++ b/crypto/sha/build.info
+@@ -88,7 +88,7 @@ DEFINE[../../providers/libdefault.a]=$SHA1DEF $KECCAK1600DEF
+ # linked with libcrypto.  Otherwise, it already gets everything that
+ # the static libcrypto.a has, and doesn't need it added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$SHA1DEF $KECCAK1600DEF
++  DEFINE[../../providers/liblegacy.a]=$SHA1DEF $KECCAK1600DEF
+ ENDIF
+ 
+ GENERATE[sha1-586.S]=asm/sha1-586.pl
diff --git a/package/libs/openssl/patches/9006.patch b/package/libs/openssl/patches/9006.patch
new file mode 100644
index 0000000..4558871
--- /dev/null
+++ b/package/libs/openssl/patches/9006.patch
@@ -0,0 +1,59 @@
+From a91c268853c4bda825a505629a873e21685490bf Mon Sep 17 00:00:00 2001
+From: "Hongren (Zenithal) Zheng" <i@zenithal.me>
+Date: Mon, 9 May 2022 19:42:39 +0800
+Subject: [PATCH] Make IV/buf in prov_cipher_ctx_st aligned
+
+Make IV/buf aligned will drastically improve performance
+as some architecture performs badly on misaligned memory
+access.
+
+Ref to
+https://gist.github.com/ZenithalHourlyRate/7b5175734f87acb73d0bbc53391d7140#file-2-openssl-long-md
+Ref to
+openssl#18197
+
+Signed-off-by: Hongren (Zenithal) Zheng <i@zenithal.me>
+
+Reviewed-by: Paul Dale <pauli@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit 2787a709c984d3884e1726383c2f2afca428d795)
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23463)
+---
+ .../implementations/include/prov/ciphercommon.h     | 13 +++++++------
+ 1 file changed, 7 insertions(+), 6 deletions(-)
+
+diff --git a/providers/implementations/include/prov/ciphercommon.h b/providers/implementations/include/prov/ciphercommon.h
+index 383b759304d45..7f9a4a3bf21a4 100644
+--- a/providers/implementations/include/prov/ciphercommon.h
++++ b/providers/implementations/include/prov/ciphercommon.h
+@@ -42,6 +42,13 @@ typedef int (PROV_CIPHER_HW_FN)(PROV_CIPHER_CTX *dat, unsigned char *out,
+ #define PROV_CIPHER_FLAG_INVERSE_CIPHER   0x0200
+ 
+ struct prov_cipher_ctx_st {
++    /* place buffer at the beginning for memory alignment */
++    /* The original value of the iv */
++    unsigned char oiv[GENERIC_BLOCK_SIZE];
++    /* Buffer of partial blocks processed via update calls */
++    unsigned char buf[GENERIC_BLOCK_SIZE];
++    unsigned char iv[GENERIC_BLOCK_SIZE];
++
+     block128_f block;
+     union {
+         cbc128_f cbc;
+@@ -83,12 +90,6 @@ struct prov_cipher_ctx_st {
+      * manage partial blocks themselves.
+      */
+     unsigned int num;
+-
+-    /* The original value of the iv */
+-    unsigned char oiv[GENERIC_BLOCK_SIZE];
+-    /* Buffer of partial blocks processed via update calls */
+-    unsigned char buf[GENERIC_BLOCK_SIZE];
+-    unsigned char iv[GENERIC_BLOCK_SIZE];
+     const PROV_CIPHER_HW *hw; /* hardware specific functions */
+     const void *ks; /* Pointer to algorithm specific key data */
+     OSSL_LIB_CTX *libctx;
diff --git a/package/libs/openssl/patches/9007.patch b/package/libs/openssl/patches/9007.patch
new file mode 100644
index 0000000..5f4edd7
--- /dev/null
+++ b/package/libs/openssl/patches/9007.patch
@@ -0,0 +1,243 @@
+From f3875dad4bca7d62c54a24ca920c06492020ce64 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 12 Jan 2024 18:47:56 +0100
+Subject: [PATCH] Fix testcases to run on duplicated keys
+
+The existing loop pattern did not really run the expected
+tests on the duplicated keys.
+
+Fixes #23129
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23292)
+
+(cherry picked from commit 387b93e14907cd8203d6f2c9d78e49df01cb6e1f)
+---
+ test/evp_extra_test.c         |  6 +++-
+ test/evp_pkey_provided_test.c | 63 +++++++++++++++++++++++++----------
+ test/keymgmt_internal_test.c  |  8 +++--
+ 3 files changed, 56 insertions(+), 21 deletions(-)
+
+diff --git a/test/evp_extra_test.c b/test/evp_extra_test.c
+index 6b484f8711ce6..e7b813493fffb 100644
+--- a/test/evp_extra_test.c
++++ b/test/evp_extra_test.c
+@@ -1100,7 +1100,7 @@ static int test_EC_priv_only_legacy(void)
+         goto err;
+     eckey = NULL;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         ctx = EVP_MD_CTX_new();
+         if (!TEST_ptr(ctx))
+@@ -1116,6 +1116,9 @@ static int test_EC_priv_only_legacy(void)
+         EVP_MD_CTX_free(ctx);
+         ctx = NULL;
+ 
++        if (dup_pk != NULL)
++            break;
++
+         if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pkey)))
+             goto err;
+         /* EVP_PKEY_eq() returns -2 with missing public keys */
+@@ -1125,6 +1128,7 @@ static int test_EC_priv_only_legacy(void)
+         if (!ret)
+             goto err;
+     }
++    ret = 1;
+ 
+  err:
+     EVP_MD_CTX_free(ctx);
+diff --git a/test/evp_pkey_provided_test.c b/test/evp_pkey_provided_test.c
+index 27f90e42a7c1c..688a8c1c5e558 100644
+--- a/test/evp_pkey_provided_test.c
++++ b/test/evp_pkey_provided_test.c
+@@ -389,7 +389,7 @@ static int test_fromdata_rsa(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 32)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 8)
+@@ -417,7 +417,10 @@ static int test_fromdata_rsa(void)
+         ret = test_print_key_using_pem("RSA", pk)
+               && test_print_key_using_encoder("RSA", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -602,7 +605,7 @@ static int test_fromdata_dh_named_group(void)
+                                                       &len)))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -682,7 +685,10 @@ static int test_fromdata_dh_named_group(void)
+         ret = test_print_key_using_pem("DH", pk)
+               && test_print_key_using_encoder("DH", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -783,7 +789,7 @@ static int test_fromdata_dh_fips186_4(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -857,7 +863,10 @@ static int test_fromdata_dh_fips186_4(void)
+         ret = test_print_key_using_pem("DH", pk)
+               && test_print_key_using_encoder("DH", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1090,7 +1099,7 @@ static int test_fromdata_ecx(int tst)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), bits)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), security_bits)
+@@ -1145,7 +1154,10 @@ static int test_fromdata_ecx(int tst)
+             ret = test_print_key_using_pem(alg, pk)
+                   && test_print_key_using_encoder(alg, pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1262,7 +1274,7 @@ static int test_fromdata_ec(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 256)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 128)
+@@ -1301,6 +1313,15 @@ static int test_fromdata_ec(void)
+             || !TEST_BN_eq(group_b, b))
+             goto err;
+ 
++        EC_GROUP_free(group);
++        group = NULL;
++        BN_free(group_p);
++        group_p = NULL;
++        BN_free(group_a);
++        group_a = NULL;
++        BN_free(group_b);
++        group_b = NULL;
++
+         if (!EVP_PKEY_get_utf8_string_param(pk, OSSL_PKEY_PARAM_GROUP_NAME,
+                                             out_curve_name,
+                                             sizeof(out_curve_name),
+@@ -1329,7 +1350,10 @@ static int test_fromdata_ec(void)
+         ret = test_print_key_using_pem(alg, pk)
+               && test_print_key_using_encoder(alg, pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1575,7 +1599,7 @@ static int test_fromdata_dsa_fips186_4(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -1624,12 +1648,12 @@ static int test_fromdata_dsa_fips186_4(void)
+                                                  &pcounter_out))
+             || !TEST_int_eq(pcounter, pcounter_out))
+             goto err;
+-        BN_free(p);
+-        p = NULL;
+-        BN_free(q);
+-        q = NULL;
+-        BN_free(g);
+-        g = NULL;
++        BN_free(p_out);
++        p_out = NULL;
++        BN_free(q_out);
++        q_out = NULL;
++        BN_free(g_out);
++        g_out = NULL;
+         BN_free(j_out);
+         j_out = NULL;
+         BN_free(pub_out);
+@@ -1657,7 +1681,10 @@ static int test_fromdata_dsa_fips186_4(void)
+         ret = test_print_key_using_pem("DSA", pk)
+               && test_print_key_using_encoder("DSA", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+diff --git a/test/keymgmt_internal_test.c b/test/keymgmt_internal_test.c
+index ce2e458f8c311..78b1cd717e95d 100644
+--- a/test/keymgmt_internal_test.c
++++ b/test/keymgmt_internal_test.c
+@@ -224,7 +224,7 @@ static int test_pass_rsa(FIXTURE *fixture)
+         || !TEST_ptr_ne(km1, km2))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         km = km3;
+         /* Check that we can't export an RSA key into an RSA-PSS keymanager */
+@@ -255,7 +255,11 @@ static int test_pass_rsa(FIXTURE *fixture)
+         }
+ 
+         ret = (ret == OSSL_NELEM(expected));
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+ 
+         ret = TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
diff --git a/package/libs/openssl/patches/9008.patch b/package/libs/openssl/patches/9008.patch
new file mode 100644
index 0000000..a32c776
--- /dev/null
+++ b/package/libs/openssl/patches/9008.patch
@@ -0,0 +1,33 @@
+From 59416d6fce255cd582fa753293bcaea4aad13be8 Mon Sep 17 00:00:00 2001
+From: Angel Baez <51308340+abaez004@users.noreply.github.com>
+Date: Wed, 7 Feb 2024 10:34:48 -0500
+Subject: [PATCH] Rearrange terms in gf_mul to prevent segfault
+
+CLA: trivial
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23512)
+
+(cherry picked from commit 76cecff5e9bedb2bafc60062283f99722697082a)
+---
+ crypto/ec/curve448/arch_64/f_impl64.c | 6 +++---
+ 1 file changed, 3 insertions(+), 3 deletions(-)
+
+diff --git a/crypto/ec/curve448/arch_64/f_impl64.c b/crypto/ec/curve448/arch_64/f_impl64.c
+index 8f7a7dd391bd8..4555b3c29a244 100644
+--- a/crypto/ec/curve448/arch_64/f_impl64.c
++++ b/crypto/ec/curve448/arch_64/f_impl64.c
+@@ -45,9 +45,9 @@ void gf_mul(gf_s * RESTRICT cs, const gf as, const gf bs)
+             accum0 += widemul(a[j + 4], b[i - j + 4]);
+         }
+         for (; j < 4; j++) {
+-            accum2 += widemul(a[j], b[i - j + 8]);
+-            accum1 += widemul(aa[j], bbb[i - j + 4]);
+-            accum0 += widemul(a[j + 4], bb[i - j + 4]);
++            accum2 += widemul(a[j], b[i + 8 - j]);
++            accum1 += widemul(aa[j], bbb[i + 4 - j]);
++            accum0 += widemul(a[j + 4], bb[i + 4 - j]);
+         }
+ 
+         accum1 -= accum2;
diff --git a/package/libs/openssl/patches/9009.patch b/package/libs/openssl/patches/9009.patch
new file mode 100644
index 0000000..deb369e
--- /dev/null
+++ b/package/libs/openssl/patches/9009.patch
@@ -0,0 +1,102 @@
+From 3732a8963d7aacde04f138204e235478609cba8a Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Wed, 7 Feb 2024 10:27:50 +0100
+Subject: [PATCH] Fix memory leaks on error cases during drbg initializations
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23503)
+
+(cherry picked from commit cb4f7a6ee053e8c51cf3ac35fee333d1f25552c0)
+---
+ providers/implementations/rands/drbg.c       | 3 ++-
+ providers/implementations/rands/drbg_ctr.c   | 5 +++--
+ providers/implementations/rands/drbg_hash.c  | 3 ++-
+ providers/implementations/rands/drbg_hmac.c  | 3 ++-
+ providers/implementations/rands/drbg_local.h | 1 +
+ 5 files changed, 10 insertions(+), 5 deletions(-)
+
+diff --git a/providers/implementations/rands/drbg.c b/providers/implementations/rands/drbg.c
+index e30836c53cabb..09edce8eb44b6 100644
+--- a/providers/implementations/rands/drbg.c
++++ b/providers/implementations/rands/drbg.c
+@@ -765,6 +765,7 @@ int ossl_drbg_enable_locking(void *vctx)
+ PROV_DRBG *ossl_rand_drbg_new
+     (void *provctx, void *parent, const OSSL_DISPATCH *p_dispatch,
+      int (*dnew)(PROV_DRBG *ctx),
++     void (*dfree)(void *vctx),
+      int (*instantiate)(PROV_DRBG *drbg,
+                         const unsigned char *entropy, size_t entropylen,
+                         const unsigned char *nonce, size_t noncelen,
+@@ -844,7 +845,7 @@ PROV_DRBG *ossl_rand_drbg_new
+     return drbg;
+ 
+  err:
+-    ossl_rand_drbg_free(drbg);
++    dfree(drbg);
+     return NULL;
+ }
+ 
+diff --git a/providers/implementations/rands/drbg_ctr.c b/providers/implementations/rands/drbg_ctr.c
+index 451113c4d1620..988a08bf93635 100644
+--- a/providers/implementations/rands/drbg_ctr.c
++++ b/providers/implementations/rands/drbg_ctr.c
+@@ -581,7 +581,7 @@ static int drbg_ctr_init(PROV_DRBG *drbg)
+     EVP_CIPHER_CTX_free(ctr->ctx_ecb);
+     EVP_CIPHER_CTX_free(ctr->ctx_ctr);
+     ctr->ctx_ecb = ctr->ctx_ctr = NULL;
+-    return 0;    
++    return 0;
+ }
+ 
+ static int drbg_ctr_new(PROV_DRBG *drbg)
+@@ -602,7 +602,8 @@ static int drbg_ctr_new(PROV_DRBG *drbg)
+ static void *drbg_ctr_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_ctr_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_ctr_new, &drbg_ctr_free,
+                               &drbg_ctr_instantiate, &drbg_ctr_uninstantiate,
+                               &drbg_ctr_reseed, &drbg_ctr_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_hash.c b/providers/implementations/rands/drbg_hash.c
+index 6deb0a29256b2..4acf9a9830e40 100644
+--- a/providers/implementations/rands/drbg_hash.c
++++ b/providers/implementations/rands/drbg_hash.c
+@@ -410,7 +410,8 @@ static int drbg_hash_new(PROV_DRBG *ctx)
+ static void *drbg_hash_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_hash_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_hash_new, &drbg_hash_free,
+                               &drbg_hash_instantiate, &drbg_hash_uninstantiate,
+                               &drbg_hash_reseed, &drbg_hash_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_hmac.c b/providers/implementations/rands/drbg_hmac.c
+index e68465a78cd9c..571f5e6f7a3b5 100644
+--- a/providers/implementations/rands/drbg_hmac.c
++++ b/providers/implementations/rands/drbg_hmac.c
+@@ -296,7 +296,8 @@ static int drbg_hmac_new(PROV_DRBG *drbg)
+ static void *drbg_hmac_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_hmac_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_hmac_new, &drbg_hmac_free,
+                               &drbg_hmac_instantiate, &drbg_hmac_uninstantiate,
+                               &drbg_hmac_reseed, &drbg_hmac_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_local.h b/providers/implementations/rands/drbg_local.h
+index 8bc5df89c2363..a2d1ef5307489 100644
+--- a/providers/implementations/rands/drbg_local.h
++++ b/providers/implementations/rands/drbg_local.h
+@@ -181,6 +181,7 @@ struct prov_drbg_st {
+ PROV_DRBG *ossl_rand_drbg_new
+     (void *provctx, void *parent, const OSSL_DISPATCH *parent_dispatch,
+      int (*dnew)(PROV_DRBG *ctx),
++     void (*dfree)(void *vctx),
+      int (*instantiate)(PROV_DRBG *drbg,
+                         const unsigned char *entropy, size_t entropylen,
+                         const unsigned char *nonce, size_t noncelen,
diff --git a/package/libs/openssl/patches/9010.patch b/package/libs/openssl/patches/9010.patch
new file mode 100644
index 0000000..5f691d6
--- /dev/null
+++ b/package/libs/openssl/patches/9010.patch
@@ -0,0 +1,38 @@
+From 112754183a720b4db0f2770a80a55805010b4e68 Mon Sep 17 00:00:00 2001
+From: Shakti Shah <shaktishah33@gmail.com>
+Date: Sun, 11 Feb 2024 01:09:10 +0530
+Subject: [PATCH] KDF_CTX_new API has incorrect signature (const should not be
+ there)
+
+https://www.openssl.org/docs/man3.1/man3/EVP_KDF_CTX.html
+
+The pages for 3.0/3.1/master seem to have the following
+EVP_KDF_CTX *EVP_KDF_CTX_new(const EVP_KDF *kdf);
+
+which does not match with the actual header which is
+EVP_KDF_CTX *EVP_KDF_CTX_new(EVP_KDF *kdf);
+
+Fixes #23532
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23541)
+
+(cherry picked from commit 4f6133f9db2b9b7ce5e59d8b8ec38202a154c524)
+---
+ doc/man3/EVP_KDF.pod | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/doc/man3/EVP_KDF.pod b/doc/man3/EVP_KDF.pod
+index 31d61b2a3df0a..9009fd21c10d5 100644
+--- a/doc/man3/EVP_KDF.pod
++++ b/doc/man3/EVP_KDF.pod
+@@ -20,7 +20,7 @@ EVP_KDF_CTX_gettable_params, EVP_KDF_CTX_settable_params - EVP KDF routines
+  typedef struct evp_kdf_st EVP_KDF;
+  typedef struct evp_kdf_ctx_st EVP_KDF_CTX;
+ 
+- EVP_KDF_CTX *EVP_KDF_CTX_new(const EVP_KDF *kdf);
++ EVP_KDF_CTX *EVP_KDF_CTX_new(EVP_KDF *kdf);
+  const EVP_KDF *EVP_KDF_CTX_kdf(EVP_KDF_CTX *ctx);
+  void EVP_KDF_CTX_free(EVP_KDF_CTX *ctx);
+  EVP_KDF_CTX *EVP_KDF_CTX_dup(const EVP_KDF_CTX *src);
diff --git a/package/libs/openssl/patches/9011.patch b/package/libs/openssl/patches/9011.patch
new file mode 100644
index 0000000..3f02a98
--- /dev/null
+++ b/package/libs/openssl/patches/9011.patch
@@ -0,0 +1,37 @@
+From 3baa3531be6374428ba0e6e650f9dc2c2b4827a6 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Sat, 16 Dec 2023 15:32:48 -0500
+Subject: [PATCH] Check for NULL cleanup function before using it in
+ encoder_process
+
+encoder_process assumes a cleanup function has been set in the currently
+in-use encoder during processing, which can lead to segfaults if said
+function hasn't been set
+
+Add a NULL check for this condition, returning -1 if it is not set
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23069)
+
+(cherry picked from commit cf57c3ecfa416afbc47d36633981034809ee6792)
+---
+ crypto/encode_decode/encoder_lib.c | 5 +++++
+ 1 file changed, 5 insertions(+)
+
+diff --git a/crypto/encode_decode/encoder_lib.c b/crypto/encode_decode/encoder_lib.c
+index 7a55c7ab9a273..74cda1ff0b2fe 100644
+--- a/crypto/encode_decode/encoder_lib.c
++++ b/crypto/encode_decode/encoder_lib.c
+@@ -59,6 +59,11 @@ int OSSL_ENCODER_to_bio(OSSL_ENCODER_CTX *ctx, BIO *out)
+         return 0;
+     }
+ 
++    if (ctx->cleanup == NULL || ctx->construct == NULL) {
++        ERR_raise(ERR_LIB_OSSL_ENCODER, ERR_R_INIT_FAIL);
++        return 0;
++    }
++
+     return encoder_process(&data) > 0;
+ }
+ 
diff --git a/package/libs/openssl/patches/9012.patch b/package/libs/openssl/patches/9012.patch
new file mode 100644
index 0000000..a0760db
--- /dev/null
+++ b/package/libs/openssl/patches/9012.patch
@@ -0,0 +1,44 @@
+From 878d31954738369c35cbafbaa65e9201e9fc6d4b Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 20 Feb 2024 15:11:26 +0000
+Subject: [PATCH] Don't print excessively long ASN1 items in fuzzer
+
+Prevent spurious fuzzer timeouts by not printing ASN1 which is excessively
+long.
+
+This fixes a false positive encountered by OSS-Fuzz.
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23640)
+
+(cherry picked from commit 4a6f70c03182b421d326831532edca32bcdb3fb1)
+---
+ fuzz/asn1.c | 14 ++++++++++----
+ 1 file changed, 10 insertions(+), 4 deletions(-)
+
+diff --git a/fuzz/asn1.c b/fuzz/asn1.c
+index ee602a08a3d91..d55554b7fd0a1 100644
+--- a/fuzz/asn1.c
++++ b/fuzz/asn1.c
+@@ -312,10 +312,16 @@ int FuzzerTestOneInput(const uint8_t *buf, size_t len)
+         ASN1_VALUE *o = ASN1_item_d2i(NULL, &b, len, i);
+ 
+         if (o != NULL) {
+-            BIO *bio = BIO_new(BIO_s_null());
+-            if (bio != NULL) {
+-                ASN1_item_print(bio, o, 4, i, pctx);
+-                BIO_free(bio);
++            /*
++             * Don't print excessively long output to prevent spurious fuzzer
++             * timeouts.
++             */
++            if (b - buf < 10000) {
++                BIO *bio = BIO_new(BIO_s_null());
++                if (bio != NULL) {
++                    ASN1_item_print(bio, o, 4, i, pctx);
++                    BIO_free(bio);
++                }
+             }
+             if (ASN1_item_i2d(o, &der, i) > 0) {
+                 OPENSSL_free(der);
diff --git a/package/libs/openssl/patches/9013.patch b/package/libs/openssl/patches/9013.patch
new file mode 100644
index 0000000..89b6241
--- /dev/null
+++ b/package/libs/openssl/patches/9013.patch
@@ -0,0 +1,42 @@
+From 6f794b461c6e16c8afb996ee190e084cbbddb6b8 Mon Sep 17 00:00:00 2001
+From: MrRurikov <96385824+MrRurikov@users.noreply.github.com>
+Date: Wed, 21 Feb 2024 11:11:34 +0300
+Subject: [PATCH] s_cb.c: Add missing return value checks
+
+Return value of function 'SSL_CTX_ctrl', that is called from
+SSL_CTX_set1_verify_cert_store() and SSL_CTX_set1_chain_cert_store(),
+is not checked, but it is usually checked for this function.
+
+CLA: trivial
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23647)
+---
+ apps/lib/s_cb.c | 6 ++++--
+ 1 file changed, 4 insertions(+), 2 deletions(-)
+
+diff --git a/apps/lib/s_cb.c b/apps/lib/s_cb.c
+index f2ddd94c3de4d..e869831e208ea 100644
+--- a/apps/lib/s_cb.c
++++ b/apps/lib/s_cb.c
+@@ -1318,7 +1318,8 @@ int ssl_load_stores(SSL_CTX *ctx,
+         if (vfyCAstore != NULL && !X509_STORE_load_store(vfy, vfyCAstore))
+             goto err;
+         add_crls_store(vfy, crls);
+-        SSL_CTX_set1_verify_cert_store(ctx, vfy);
++        if (SSL_CTX_set1_verify_cert_store(ctx, vfy) == 0)
++            goto err;
+         if (crl_download)
+             store_setup_crl_download(vfy);
+     }
+@@ -1332,7 +1333,8 @@ int ssl_load_stores(SSL_CTX *ctx,
+             goto err;
+         if (chCAstore != NULL && !X509_STORE_load_store(ch, chCAstore))
+             goto err;
+-        SSL_CTX_set1_chain_cert_store(ctx, ch);
++        if (SSL_CTX_set1_chain_cert_store(ctx, ch) == 0)
++            goto err;
+     }
+     rv = 1;
+  err:
diff --git a/package/libs/openssl/patches/9014.patch b/package/libs/openssl/patches/9014.patch
new file mode 100644
index 0000000..6b1b7c0
--- /dev/null
+++ b/package/libs/openssl/patches/9014.patch
@@ -0,0 +1,103 @@
+From d9d260eb95ec129b93a55965b6f2f392df0ed0a9 Mon Sep 17 00:00:00 2001
+From: Michael Baentsch <57787676+baentsch@users.noreply.github.com>
+Date: Mon, 19 Feb 2024 06:41:35 +0100
+Subject: [PATCH] SSL_set1_groups_list(): Fix memory corruption with 40 groups
+ and more
+
+Fixes #23624
+
+The calculation of the size for gid_arr reallocation was wrong.
+A multiplication by gid_arr array item size was missing.
+
+Testcase is added.
+
+Reviewed-by: Nicola Tuveri <nic.tuv@gmail.com>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Cherry-pick from https://github.com/openssl/openssl/pull/23625)
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23661)
+---
+ ssl/t1_lib.c        |  3 ++-
+ test/sslapitest.c   | 15 ++++-----------
+ test/tls-provider.c |  7 +++++--
+ 3 files changed, 11 insertions(+), 14 deletions(-)
+
+diff --git a/ssl/t1_lib.c b/ssl/t1_lib.c
+index 8be00a4f34059..d775ba56da935 100644
+--- a/ssl/t1_lib.c
++++ b/ssl/t1_lib.c
+@@ -734,7 +734,8 @@ static int gid_cb(const char *elem, int len, void *arg)
+         return 0;
+     if (garg->gidcnt == garg->gidmax) {
+         uint16_t *tmp =
+-            OPENSSL_realloc(garg->gid_arr, garg->gidmax + GROUPLIST_INCREMENT);
++            OPENSSL_realloc(garg->gid_arr,
++                            (garg->gidmax + GROUPLIST_INCREMENT) * sizeof(*garg->gid_arr));
+         if (tmp == NULL)
+             return 0;
+         garg->gidmax += GROUPLIST_INCREMENT;
+diff --git a/test/sslapitest.c b/test/sslapitest.c
+index e0274f12f7cc5..231f49819949a 100644
+--- a/test/sslapitest.c
++++ b/test/sslapitest.c
+@@ -9269,20 +9269,11 @@ static int test_pluggable_group(int idx)
+     OSSL_PROVIDER *tlsprov = OSSL_PROVIDER_load(libctx, "tls-provider");
+     /* Check that we are not impacted by a provider without any groups */
+     OSSL_PROVIDER *legacyprov = OSSL_PROVIDER_load(libctx, "legacy");
+-    const char *group_name = idx == 0 ? "xorgroup" : "xorkemgroup";
++    const char *group_name = idx == 0 ? "xorkemgroup" : "xorgroup";
+ 
+     if (!TEST_ptr(tlsprov))
+         goto end;
+ 
+-    if (legacyprov == NULL) {
+-        /*
+-         * In this case we assume we've been built with "no-legacy" and skip
+-         * this test (there is no OPENSSL_NO_LEGACY)
+-         */
+-        testresult = 1;
+-        goto end;
+-    }
+-
+     if (!TEST_true(create_ssl_ctx_pair(libctx, TLS_server_method(),
+                                        TLS_client_method(),
+                                        TLS1_3_VERSION,
+@@ -9292,7 +9283,9 @@ static int test_pluggable_group(int idx)
+                                              NULL, NULL)))
+         goto end;
+ 
+-    if (!TEST_true(SSL_set1_groups_list(serverssl, group_name))
++    /* ensure GROUPLIST_INCREMENT (=40) logic triggers: */
++    if (!TEST_true(SSL_set1_groups_list(serverssl, "xorgroup:xorkemgroup:dummy1:dummy2:dummy3:dummy4:dummy5:dummy6:dummy7:dummy8:dummy9:dummy10:dummy11:dummy12:dummy13:dummy14:dummy15:dummy16:dummy17:dummy18:dummy19:dummy20:dummy21:dummy22:dummy23:dummy24:dummy25:dummy26:dummy27:dummy28:dummy29:dummy30:dummy31:dummy32:dummy33:dummy34:dummy35:dummy36:dummy37:dummy38:dummy39:dummy40:dummy41:dummy42:dummy43"))
++    /* removing a single algorithm from the list makes the test pass */
+             || !TEST_true(SSL_set1_groups_list(clientssl, group_name)))
+         goto end;
+ 
+diff --git a/test/tls-provider.c b/test/tls-provider.c
+index 5c44b6812e816..eff6f76150bfc 100644
+--- a/test/tls-provider.c
++++ b/test/tls-provider.c
+@@ -210,6 +210,8 @@ static int tls_prov_get_capabilities(void *provctx, const char *capability,
+         }
+         dummygroup[0].data = dummy_group_names[i];
+         dummygroup[0].data_size = strlen(dummy_group_names[i]) + 1;
++        /* assign unique group IDs also to dummy groups for registration */
++        *((int *)(dummygroup[3].data)) = 65279 - NUM_DUMMY_GROUPS + i;
+         ret &= cb(dummygroup, arg);
+     }
+ 
+@@ -817,9 +819,10 @@ unsigned int randomize_tls_group_id(OSSL_LIB_CTX *libctx)
+         return 0;
+     /*
+      * Ensure group_id is within the IANA Reserved for private use range
+-     * (65024-65279)
++     * (65024-65279).
++     * Carve out NUM_DUMMY_GROUPS ids for properly registering those.
+      */
+-    group_id %= 65279 - 65024;
++    group_id %= 65279 - NUM_DUMMY_GROUPS - 65024;
+     group_id += 65024;
+ 
+     /* Ensure we did not already issue this group_id */
diff --git a/package/libs/openssl/patches/9015.patch b/package/libs/openssl/patches/9015.patch
new file mode 100644
index 0000000..b1c342d
--- /dev/null
+++ b/package/libs/openssl/patches/9015.patch
@@ -0,0 +1,29 @@
+From d44aa28b0db3ba355fe68c5971c90c9a1414788f Mon Sep 17 00:00:00 2001
+From: shridhar kalavagunta <coolshrid@hotmail.com>
+Date: Fri, 26 Jan 2024 21:10:32 -0600
+Subject: [PATCH] Fix off by one issue in buf2hexstr_sep()
+
+Fixes #23363
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23404)
+
+(cherry picked from commit c5cc9c419a0a8d97a44f01f95f0e213f56da4574)
+---
+ crypto/o_str.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/crypto/o_str.c b/crypto/o_str.c
+index 7fa487dd5fcde..bfbc2ca5e372c 100644
+--- a/crypto/o_str.c
++++ b/crypto/o_str.c
+@@ -251,7 +251,7 @@ static int buf2hexstr_sep(char *str, size_t str_n, size_t *strlength,
+     *q = CH_ZERO;
+ 
+ #ifdef CHARSET_EBCDIC
+-    ebcdic2ascii(str, str, q - str - 1);
++    ebcdic2ascii(str, str, q - str);
+ #endif
+     return 1;
+ }
diff --git a/package/libs/openssl/patches/9016.patch b/package/libs/openssl/patches/9016.patch
new file mode 100644
index 0000000..bcbbf8d
--- /dev/null
+++ b/package/libs/openssl/patches/9016.patch
@@ -0,0 +1,29 @@
+From 17d12183797033f55aec03376ffd3969cd703c0e Mon Sep 17 00:00:00 2001
+From: Vladimirs Ambrosovs <rodriguez.twister@gmail.com>
+Date: Tue, 12 Mar 2024 18:23:55 +0200
+Subject: [PATCH] Fix dasync_rsa_decrypt to call EVP_PKEY_meth_get_decrypt
+
+Signed-off-by: Vladimirs Ambrosovs <rodriguez.twister@gmail.com>
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23825)
+
+(cherry picked from commit c91f0ca95881d03a54aedee197bbf5ffffc02935)
+---
+ engines/e_dasync.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/engines/e_dasync.c b/engines/e_dasync.c
+index 7974106ae2197..aa7b2bce2f7cf 100644
+--- a/engines/e_dasync.c
++++ b/engines/e_dasync.c
+@@ -985,7 +985,7 @@ static int dasync_rsa_decrypt(EVP_PKEY_CTX *ctx, unsigned char *out,
+                              size_t inlen);
+ 
+     if (pdecrypt == NULL)
+-        EVP_PKEY_meth_get_encrypt(dasync_rsa_orig, NULL, &pdecrypt);
++        EVP_PKEY_meth_get_decrypt(dasync_rsa_orig, NULL, &pdecrypt);
+     return pdecrypt(ctx, out, outlen, in, inlen);
+ }
+ 
diff --git a/package/libs/openssl/patches/9017.patch b/package/libs/openssl/patches/9017.patch
new file mode 100644
index 0000000..dd1a756
--- /dev/null
+++ b/package/libs/openssl/patches/9017.patch
@@ -0,0 +1,75 @@
+From a473d59db1ce6943c010c5ba842e7c17fbe81aab Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Wed, 13 Mar 2024 15:19:43 +0000
+Subject: [PATCH] Fix unbounded memory growth when using no-cached-fetch
+
+When OpenSSL has been compiled with no-cached-fetch we do not cache
+algorithms fetched from a provider. When we export an EVP_PKEY to a
+provider we cache the details of that export in the operation cache for
+that EVP_PKEY. Amoung the details we cache is the EVP_KEYMGMT that we used
+for the export. When we come to reuse the key in the same provider that
+we have previously exported the key to, we check the operation cache for
+the cached key data. However because the EVP_KEYMGMT instance was not
+cached then instance will be different every time and we were not
+recognising that we had already exported the key to the provider.
+
+This causes us to re-export the key to the same provider everytime the key
+is used. Since this consumes memory we end up with unbounded memory growth.
+
+The fix is to be more intelligent about recognising that we have already
+exported key data to a given provider even if the EVP_KEYMGMT instance is
+different.
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/23841)
+
+(cherry picked from commit dc9bc6c8e1bd329ead703417a2235ab3e97557ec)
+---
+ crypto/evp/keymgmt_lib.c |  7 ++++++-
+ crypto/evp/p_lib.c       | 10 +++++++++-
+ 2 files changed, 15 insertions(+), 2 deletions(-)
+
+diff --git a/crypto/evp/keymgmt_lib.c b/crypto/evp/keymgmt_lib.c
+index 8369d9578cbd0..3226786bb5db5 100644
+--- a/crypto/evp/keymgmt_lib.c
++++ b/crypto/evp/keymgmt_lib.c
+@@ -243,10 +243,15 @@ OP_CACHE_ELEM *evp_keymgmt_util_find_operation_cache(EVP_PKEY *pk,
+     /*
+      * A comparison and sk_P_CACHE_ELEM_find() are avoided to not cause
+      * problems when we've only a read lock.
++     * A keymgmt is a match if the |keymgmt| pointers are identical or if the
++     * provider and the name ID match
+      */
+     for (i = 0; i < end; i++) {
+         p = sk_OP_CACHE_ELEM_value(pk->operation_cache, i);
+-        if (keymgmt == p->keymgmt && (p->selection & selection) == selection)
++        if ((p->selection & selection) == selection
++                && (keymgmt == p->keymgmt
++                    || (keymgmt->name_id == p->keymgmt->name_id
++                        && keymgmt->prov == p->keymgmt->prov)))
+             return p;
+     }
+     return NULL;
+diff --git a/crypto/evp/p_lib.c b/crypto/evp/p_lib.c
+index 04b148a912187..119d80fa0050e 100644
+--- a/crypto/evp/p_lib.c
++++ b/crypto/evp/p_lib.c
+@@ -1902,7 +1902,15 @@ void *evp_pkey_export_to_provider(EVP_PKEY *pk, OSSL_LIB_CTX *libctx,
+              * If |tmp_keymgmt| is present in the operation cache, it means
+              * that export doesn't need to be redone.  In that case, we take
+              * token copies of the cached pointers, to have token success
+-             * values to return.
++             * values to return. It is possible (e.g. in a no-cached-fetch
++             * build), for op->keymgmt to be a different pointer to tmp_keymgmt
++             * even though the name/provider must be the same. In other words
++             * the keymgmt instance may be different but still equivalent, i.e.
++             * same algorithm/provider instance - but we make the simplifying
++             * assumption that the keydata can be used with either keymgmt
++             * instance. Not doing so introduces significant complexity and
++             * probably requires refactoring - since we would have to ripple
++             * the change in keymgmt instance up the call chain.
+              */
+             if (op != NULL && op->keymgmt != NULL) {
+                 keydata = op->keydata;
diff --git a/package/libs/openssl/patches/9018.patch b/package/libs/openssl/patches/9018.patch
new file mode 100644
index 0000000..f8ba021
--- /dev/null
+++ b/package/libs/openssl/patches/9018.patch
@@ -0,0 +1,46 @@
+From 99a1c93efa751f8c9ee06aafe877a2d8bdbdf990 Mon Sep 17 00:00:00 2001
+From: Jiasheng Jiang <jiasheng@purdue.edu>
+Date: Thu, 21 Mar 2024 19:55:34 +0000
+Subject: [PATCH] Replace unsigned with int
+
+Replace the type of "digest_length" with int to avoid implicit conversion when it is assigned by EVP_MD_get_size().
+Otherwise, it may pass the following check and cause the integer overflow error when EVP_MD_get_size() returns negative numbers.
+Signed-off-by: Jiasheng Jiang <jiasheng@purdue.edu>
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23922)
+
+(cherry picked from commit f13ddaab69def0b453b75a8f2deb80e1f1634f42)
+---
+ demos/digest/EVP_MD_demo.c  | 2 +-
+ demos/digest/EVP_MD_stdin.c | 2 +-
+ 2 files changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/demos/digest/EVP_MD_demo.c b/demos/digest/EVP_MD_demo.c
+index 99589bd3446b6..7cb7936b59fa2 100644
+--- a/demos/digest/EVP_MD_demo.c
++++ b/demos/digest/EVP_MD_demo.c
+@@ -83,7 +83,7 @@ int demonstrate_digest(void)
+     const char *option_properties = NULL;
+     EVP_MD *message_digest = NULL;
+     EVP_MD_CTX *digest_context = NULL;
+-    unsigned int digest_length;
++    int digest_length;
+     unsigned char *digest_value = NULL;
+     int j;
+ 
+diff --git a/demos/digest/EVP_MD_stdin.c b/demos/digest/EVP_MD_stdin.c
+index 71a3d325a364e..07813acdc94f7 100644
+--- a/demos/digest/EVP_MD_stdin.c
++++ b/demos/digest/EVP_MD_stdin.c
+@@ -38,7 +38,7 @@ int demonstrate_digest(BIO *input)
+     const char * option_properties = NULL;
+     EVP_MD *message_digest = NULL;
+     EVP_MD_CTX *digest_context = NULL;
+-    unsigned int digest_length;
++    int digest_length;
+     unsigned char *digest_value = NULL;
+     unsigned char buffer[512];
+     int ii;
diff --git a/package/libs/openssl/patches/9019.patch b/package/libs/openssl/patches/9019.patch
new file mode 100644
index 0000000..ea84015
--- /dev/null
+++ b/package/libs/openssl/patches/9019.patch
@@ -0,0 +1,78 @@
+From 95dfb4244a8b6f23768714619f4f4640d51dc3ff Mon Sep 17 00:00:00 2001
+From: =?UTF-8?q?Viliam=20Lej=C4=8D=C3=ADk?= <lejcik@gmail.com>
+Date: Mon, 19 Feb 2024 21:39:05 +0100
+Subject: [PATCH] Add NULL check before accessing PKCS7 encrypted algorithm
+
+Printing content of an invalid test certificate causes application crash, because of NULL dereference:
+
+user@user:~/openssl$ openssl pkcs12 -in test/recipes/80-test_pkcs12_data/bad2.p12 -passin pass: -info
+MAC: sha256, Iteration 2048
+MAC length: 32, salt length: 8
+PKCS7 Encrypted data: Segmentation fault (core dumped)
+
+Added test cases for pkcs12 bad certificates
+
+Reviewed-by: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23632)
+
+(cherry picked from commit a4cbffcd8998180b98bb9f7ce6065ed37d079d8b)
+---
+ apps/pkcs12.c                 |  6 +++++-
+ test/recipes/80-test_pkcs12.t | 14 +++++++++++++-
+ 2 files changed, 18 insertions(+), 2 deletions(-)
+
+diff --git a/apps/pkcs12.c b/apps/pkcs12.c
+index b442d358f8b70..af4f9fce04b16 100644
+--- a/apps/pkcs12.c
++++ b/apps/pkcs12.c
+@@ -855,7 +855,11 @@ int dump_certs_keys_p12(BIO *out, const PKCS12 *p12, const char *pass,
+         } else if (bagnid == NID_pkcs7_encrypted) {
+             if (options & INFO) {
+                 BIO_printf(bio_err, "PKCS7 Encrypted data: ");
+-                alg_print(p7->d.encrypted->enc_data->algorithm);
++                if (p7->d.encrypted == NULL) {
++                    BIO_printf(bio_err, "<no data>\n");
++                } else {
++                    alg_print(p7->d.encrypted->enc_data->algorithm);
++                }
+             }
+             bags = PKCS12_unpack_p7encdata(p7, pass, passlen);
+         } else {
+diff --git a/test/recipes/80-test_pkcs12.t b/test/recipes/80-test_pkcs12.t
+index 4c5bb5744b8c5..de26cbdca4dc7 100644
+--- a/test/recipes/80-test_pkcs12.t
++++ b/test/recipes/80-test_pkcs12.t
+@@ -54,7 +54,7 @@ if (eval { require Win32::API; 1; }) {
+ }
+ $ENV{OPENSSL_WIN32_UTF8}=1;
+ 
+-plan tests => 17;
++plan tests => 20;
+ 
+ # Test different PKCS#12 formats
+ ok(run(test(["pkcs12_format_test"])), "test pkcs12 formats");
+@@ -162,11 +162,23 @@ with({ exit_checker => sub { return shift == 1; } },
+                     "-nomacver"])),
+            "test bad pkcs12 file 1 (nomacver)");
+ 
++        ok(run(app(["openssl", "pkcs12", "-in", $bad1, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 1 (info)");
++
+         ok(run(app(["openssl", "pkcs12", "-in", $bad2, "-password", "pass:"])),
+            "test bad pkcs12 file 2");
+ 
++        ok(run(app(["openssl", "pkcs12", "-in", $bad2, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 2 (info)");
++
+         ok(run(app(["openssl", "pkcs12", "-in", $bad3, "-password", "pass:"])),
+            "test bad pkcs12 file 3");
++
++        ok(run(app(["openssl", "pkcs12", "-in", $bad3, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 3 (info)");
+      });
+ 
+ SetConsoleOutputCP($savedcp) if (defined($savedcp));
-- 
2.38.1.windows.1

