diff --git a/package/libs/openssl/patches/0020.patch b/package/libs/openssl/patches/0020.patch
new file mode 100644
index 0000000..484f747
--- /dev/null
+++ b/package/libs/openssl/patches/0020.patch
@@ -0,0 +1,74 @@
+From 845e6824098cd0845c85af0f19afc904b8f48111 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Fri, 23 Feb 2024 10:32:14 +0100
+Subject: [PATCH] Fix openssl req with -addext subjectAltName=dirName
+
+The syntax check of the -addext fails because the
+X509V3_CTX is used to lookup the referenced section,
+but the wrong configuration file is used, where only
+a default section with all passed in -addext lines is available.
+Thus it was not possible to use the subjectAltName=dirName:section
+as an -addext parameter.  Probably other extensions as well.
+
+This change affects only the syntax check, the real extension
+was already created with correct parameters.
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23669)
+
+(cherry picked from commit 387418893e45e588d1cbd4222549b5113437c9ab)
+---
+ apps/req.c                 | 2 +-
+ test/recipes/25-test_req.t | 3 ++-
+ test/test.cnf              | 6 ++++++
+ 3 files changed, 9 insertions(+), 2 deletions(-)
+
+diff --git a/apps/req.c b/apps/req.c
+index c7d4c7822cda9..2fc53d4bfcfa2 100644
+--- a/apps/req.c
++++ b/apps/req.c
+@@ -569,7 +569,7 @@ int req_main(int argc, char **argv)
+         X509V3_CTX ctx;
+ 
+         X509V3_set_ctx_test(&ctx);
+-        X509V3_set_nconf(&ctx, addext_conf);
++        X509V3_set_nconf(&ctx, req_conf);
+         if (!X509V3_EXT_add_nconf(addext_conf, &ctx, "default", NULL)) {
+             BIO_printf(bio_err, "Error checking extensions defined using -addext\n");
+             goto end;
+diff --git a/test/recipes/25-test_req.t b/test/recipes/25-test_req.t
+index fe02d29c634f2..932635f4b2c18 100644
+--- a/test/recipes/25-test_req.t
++++ b/test/recipes/25-test_req.t
+@@ -15,7 +15,7 @@ use OpenSSL::Test qw/:DEFAULT srctop_file/;
+ 
+ setup("test_req");
+ 
+-plan tests => 49;
++plan tests => 50;
+ 
+ require_ok(srctop_file('test', 'recipes', 'tconversion.pl'));
+ 
+@@ -53,6 +53,7 @@ ok(!run(app([@addext_args, "-addext", $val, "-addext", $val2])));
+ ok(!run(app([@addext_args, "-addext", $val, "-addext", $val3])));
+ ok(!run(app([@addext_args, "-addext", $val2, "-addext", $val3])));
+ ok(run(app([@addext_args, "-addext", "SXNetID=1:one, 2:two, 3:three"])));
++ok(run(app([@addext_args, "-addext", "subjectAltName=dirName:dirname_sec"])));
+ 
+ # If a CSR is provided with neither of -key or -CA/-CAkey, this should fail.
+ ok(!run(app(["openssl", "req", "-x509",
+diff --git a/test/test.cnf b/test/test.cnf
+index 8b2f92ad8e241..8f68982a9fa1f 100644
+--- a/test/test.cnf
++++ b/test/test.cnf
+@@ -72,3 +72,9 @@ commonName			= CN field
+ commonName_value		= Eric Young
+ emailAddress			= email field
+ emailAddress_value		= eay@mincom.oz.au
++
++[ dirname_sec ]
++C  = UK
++O  = My Organization
++OU = My Unit
++CN = My Name
diff --git a/package/libs/openssl/patches/0021.patch b/package/libs/openssl/patches/0021.patch
new file mode 100644
index 0000000..0dcb23c
--- /dev/null
+++ b/package/libs/openssl/patches/0021.patch
@@ -0,0 +1,169 @@
+From 2fe6c0fbb5ae7e2279e80d7cdff99a1bd2a45733 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Thu, 8 Feb 2024 22:21:55 +0100
+Subject: [PATCH] Fix handling of NULL sig parameter in ECDSA_sign and similar
+
+The problem is, that it almost works to pass sig=NULL to the
+ECDSA_sign, ECDSA_sign_ex and DSA_sign, to compute the necessary
+space for the resulting signature.
+But since the ECDSA signature is non-deterministic
+(except when ECDSA_sign_setup/ECDSA_sign_ex are used)
+the resulting length may be different when the API is called again.
+This can easily cause random memory corruption.
+Several internal APIs had the same issue, but since they are
+never called with sig=NULL, it is better to make them return an
+error in that case, instead of making the code more complex.
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23529)
+
+(cherry picked from commit 1fa2bf9b1885d2e87524421fea5041d40149cffa)
+---
+ crypto/dsa/dsa_sign.c  |  7 ++++++-
+ crypto/ec/ecdsa_ossl.c |  5 +++++
+ crypto/sm2/sm2_sign.c  |  7 ++++++-
+ test/dsatest.c         |  8 ++++++--
+ test/ecdsatest.c       | 28 ++++++++++++++++++++++++++--
+ 5 files changed, 49 insertions(+), 6 deletions(-)
+
+diff --git a/crypto/dsa/dsa_sign.c b/crypto/dsa/dsa_sign.c
+index ddfbfa18af157..2f963af8e123c 100644
+--- a/crypto/dsa/dsa_sign.c
++++ b/crypto/dsa/dsa_sign.c
+@@ -156,6 +156,11 @@ int ossl_dsa_sign_int(int type, const unsigned char *dgst, int dlen,
+ {
+     DSA_SIG *s;
+ 
++    if (sig == NULL) {
++        *siglen = DSA_size(dsa);
++        return 1;
++    }
++
+     /* legacy case uses the method table */
+     if (dsa->libctx == NULL || dsa->meth != DSA_get_default_method())
+         s = DSA_do_sign(dgst, dlen, dsa);
+@@ -165,7 +170,7 @@ int ossl_dsa_sign_int(int type, const unsigned char *dgst, int dlen,
+         *siglen = 0;
+         return 0;
+     }
+-    *siglen = i2d_DSA_SIG(s, sig != NULL ? &sig : NULL);
++    *siglen = i2d_DSA_SIG(s, &sig);
+     DSA_SIG_free(s);
+     return 1;
+ }
+diff --git a/crypto/ec/ecdsa_ossl.c b/crypto/ec/ecdsa_ossl.c
+index 0bf4635e2f972..0bdf45e6e77de 100644
+--- a/crypto/ec/ecdsa_ossl.c
++++ b/crypto/ec/ecdsa_ossl.c
+@@ -70,6 +70,11 @@ int ossl_ecdsa_sign(int type, const unsigned char *dgst, int dlen,
+ {
+     ECDSA_SIG *s;
+ 
++    if (sig == NULL && (kinv == NULL || r == NULL)) {
++        *siglen = ECDSA_size(eckey);
++        return 1;
++    }
++
+     s = ECDSA_do_sign_ex(dgst, dlen, kinv, r, eckey);
+     if (s == NULL) {
+         *siglen = 0;
+diff --git a/crypto/sm2/sm2_sign.c b/crypto/sm2/sm2_sign.c
+index ff5be9b73e9fb..09e542990bcb3 100644
+--- a/crypto/sm2/sm2_sign.c
++++ b/crypto/sm2/sm2_sign.c
+@@ -442,6 +442,11 @@ int ossl_sm2_internal_sign(const unsigned char *dgst, int dgstlen,
+     int sigleni;
+     int ret = -1;
+ 
++    if (sig == NULL) {
++        ERR_raise(ERR_LIB_SM2, ERR_R_PASSED_NULL_PARAMETER);
++        goto done;
++    }
++
+     e = BN_bin2bn(dgst, dgstlen, NULL);
+     if (e == NULL) {
+        ERR_raise(ERR_LIB_SM2, ERR_R_BN_LIB);
+@@ -454,7 +459,7 @@ int ossl_sm2_internal_sign(const unsigned char *dgst, int dgstlen,
+         goto done;
+     }
+ 
+-    sigleni = i2d_ECDSA_SIG(s, sig != NULL ? &sig : NULL);
++    sigleni = i2d_ECDSA_SIG(s, &sig);
+     if (sigleni < 0) {
+        ERR_raise(ERR_LIB_SM2, ERR_R_INTERNAL_ERROR);
+        goto done;
+diff --git a/test/dsatest.c b/test/dsatest.c
+index 5fa83020f87a2..73c6827bb0def 100644
+--- a/test/dsatest.c
++++ b/test/dsatest.c
+@@ -332,6 +332,7 @@ static int test_dsa_sig_infinite_loop(void)
+     BIGNUM *p = NULL, *q = NULL, *g = NULL, *priv = NULL, *pub = NULL, *priv2 = NULL;
+     BIGNUM *badq = NULL, *badpriv = NULL;
+     const unsigned char msg[] = { 0x00 };
++    unsigned int signature_len0;
+     unsigned int signature_len;
+     unsigned char signature[64];
+ 
+@@ -375,10 +376,13 @@ static int test_dsa_sig_infinite_loop(void)
+         goto err;
+ 
+     /* Test passing signature as NULL */
+-    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), NULL, &signature_len, dsa)))
++    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), NULL, &signature_len0, dsa))
++        || !TEST_int_gt(signature_len0, 0))
+         goto err;
+ 
+-    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), signature, &signature_len, dsa)))
++    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), signature, &signature_len, dsa))
++        || !TEST_int_gt(signature_len, 0)
++        || !TEST_int_le(signature_len, signature_len0))
+         goto err;
+ 
+     /* Test using a private key of zero fails - this causes an infinite loop without the retry test */
+diff --git a/test/ecdsatest.c b/test/ecdsatest.c
+index 33a52eb1b5624..ded41be5bdcd0 100644
+--- a/test/ecdsatest.c
++++ b/test/ecdsatest.c
+@@ -350,15 +350,39 @@ static int test_builtin_as_sm2(int n)
+ static int test_ecdsa_sig_NULL(void)
+ {
+     int ret;
++    unsigned int siglen0;
+     unsigned int siglen;
+     unsigned char dgst[128] = { 0 };
+     EC_KEY *eckey = NULL;
++    unsigned char *sig = NULL;
++    BIGNUM *kinv = NULL, *rp = NULL;
+ 
+     ret = TEST_ptr(eckey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1))
+           && TEST_int_eq(EC_KEY_generate_key(eckey), 1)
+-          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), NULL, &siglen, eckey), 1)
+-          && TEST_int_gt(siglen, 0);
++          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), NULL, &siglen0,
++                                    eckey), 1)
++          && TEST_int_gt(siglen0, 0)
++          && TEST_ptr(sig = OPENSSL_malloc(siglen0))
++          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), sig, &siglen,
++                                    eckey), 1)
++          && TEST_int_gt(siglen, 0)
++          && TEST_int_le(siglen, siglen0)
++          && TEST_int_eq(ECDSA_verify(0, dgst, sizeof(dgst), sig, siglen,
++                                      eckey), 1)
++          && TEST_int_eq(ECDSA_sign_setup(eckey, NULL, &kinv, &rp), 1)
++          && TEST_int_eq(ECDSA_sign_ex(0, dgst, sizeof(dgst), NULL, &siglen,
++                                       kinv, rp, eckey), 1)
++          && TEST_int_gt(siglen, 0)
++          && TEST_int_le(siglen, siglen0)
++          && TEST_int_eq(ECDSA_sign_ex(0, dgst, sizeof(dgst), sig, &siglen0,
++                                       kinv, rp, eckey), 1)
++          && TEST_int_eq(siglen, siglen0)
++          && TEST_int_eq(ECDSA_verify(0, dgst, sizeof(dgst), sig, siglen,
++                                      eckey), 1);
+     EC_KEY_free(eckey);
++    OPENSSL_free(sig);
++    BN_free(kinv);
++    BN_free(rp);
+     return ret;
+ }
+ 
-- 
2.38.1.windows.1

