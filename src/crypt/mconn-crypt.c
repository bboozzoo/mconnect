/**
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * AUTHORS
 * Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */
#include <openssl/rsa.h>
#include <openssl/bio.h>
#include <openssl/pem.h>
#include "mconn-crypt.h"

/* encrypted data padding */
#define MCONN_CRYPT_RSA_PADDING RSA_PKCS1_PADDING

typedef struct _MconnCryptPrivate	   MconnCryptPrivate;

/**
 * MconnCrypt:
 *
 * A simple wrapper for cypto operations.
 **/

struct _MconnCrypt
{
	GObject parent;
	MconnCryptPrivate *priv;
};

struct _MconnCryptPrivate
{
	RSA	  *key;					/* RSA key wrapper */
};

static void mconn_crypt_dispose (GObject *object);
static void mconn_crypt_finalize (GObject *object);
static gchar *__mconn_get_public_key_as_pem(MconnCryptPrivate *priv);
static gboolean __mconn_load_key(MconnCryptPrivate *priv, const char *path);
static gboolean __mconn_generate_key_at_path(const char *path);

G_DEFINE_TYPE_WITH_PRIVATE (MconnCrypt, mconn_crypt, G_TYPE_OBJECT);

static void
mconn_crypt_class_init (MconnCryptClass *klass)
{
	GObjectClass *gobject_class = (GObjectClass *)klass;

	gobject_class->dispose = mconn_crypt_dispose;
	gobject_class->finalize = mconn_crypt_finalize;
}

static void
mconn_crypt_init (MconnCrypt *self)
{
	g_debug("mconn-crypt: new instance");
	self->priv = mconn_crypt_get_instance_private(self);
}

static void
mconn_crypt_dispose (GObject *object)
{
	MconnCrypt *self = (MconnCrypt *)object;

	if (self->priv->key != NULL)
	{
		RSA_free(self->priv->key);
		self->priv->key = NULL;
	}

	G_OBJECT_CLASS (mconn_crypt_parent_class)->dispose (object);
}

static void
mconn_crypt_finalize (GObject *object)
{
	MconnCrypt *self = (MconnCrypt *)object;

	g_signal_handlers_destroy (object);
	G_OBJECT_CLASS (mconn_crypt_parent_class)->finalize (object);
}

MconnCrypt *mconn_crypt_new_for_key_path(const char *path)
{
	g_debug("mconn-crypt: new crypt for key %s", path);

	MconnCrypt *self = g_object_new(MCONN_TYPE_CRYPT, NULL);

	if (g_file_test(path, G_FILE_TEST_EXISTS) == FALSE)
		__mconn_generate_key_at_path(path);

	if (__mconn_load_key(self->priv, path) == FALSE)
	{
		mconn_crypt_unref(self);
		return NULL;
	}

	return self;
}

MconnCrypt * mconn_crypt_ref(MconnCrypt *self)
{
	g_assert(IS_MCONN_CRYPT(self));
	return MCONN_CRYPT(g_object_ref(self));
}

void mconn_crypt_unref(MconnCrypt *self)
{
	if (self != NULL)
	{
		g_assert(IS_MCONN_CRYPT(self));
		g_object_unref(self);
	}
}

GByteArray * mconn_crypt_decrypt(MconnCrypt *self, GBytes *data, GError **err)
{
	g_assert(IS_MCONN_CRYPT(self));
	g_assert(self->priv->key);

	/* g_debug("decrypt: %zu bytes of data", g_bytes_get_size(data)); */

	g_assert_cmpint(g_bytes_get_size(data), ==, RSA_size(self->priv->key));

	/* decrypted data is less than RSA_size() long */
	gsize out_buf_size = RSA_size(self->priv->key);
	GByteArray *out_data = g_byte_array_sized_new(out_buf_size);

	int dec_size;
	dec_size = RSA_private_decrypt(g_bytes_get_size(data),
								   g_bytes_get_data(data, NULL),
								   (unsigned char *)out_data->data,
								   self->priv->key,
								   MCONN_CRYPT_RSA_PADDING);
	/* g_debug("decrypted size: %d", dec_size); */
	g_assert(dec_size != -1);

	g_byte_array_set_size(out_data, dec_size);

	return out_data;
}

gchar *mconn_crypt_get_public_key_pem(MconnCrypt *self)
{
	g_assert(IS_MCONN_CRYPT(self));
	g_assert(self->priv);
	g_assert(self->priv->key);
	return __mconn_get_public_key_as_pem(self->priv);
}

/**
 *
 */
static gchar *__mconn_get_public_key_as_pem(MconnCryptPrivate *priv)
{
	gchar *pubkey = NULL;

	/* memory IO  */
	BIO *bm = BIO_new(BIO_s_mem());

	/* generate PEM */
	/* PEM_write_bio_RSAPublicKey(bm, priv->key); */
	PEM_write_bio_RSA_PUBKEY(bm, priv->key);

	/* get PEM as text */
	char *oss_pubkey = NULL;
	long data = BIO_get_mem_data(bm, &oss_pubkey);
	g_debug("mconn-crypt: public key length: %ld", data);
	g_assert(data != 0);
	g_assert(oss_pubkey != NULL);

	/* dup the key as buffer goes away with BIO */
	pubkey = g_strndup(oss_pubkey, data);

	BIO_set_close(bm, BIO_CLOSE);
	BIO_free(bm);

	return pubkey;
}

static gboolean __mconn_load_key(MconnCryptPrivate *priv, const char *path)
{
	if (g_file_test(path, G_FILE_TEST_EXISTS) == FALSE)
	{
		g_critical("mconn-crypt: key file %s does not exist", path);
		return FALSE;
	}

	g_debug("mconn-crypt: loading key from %s", path);

	BIO *bf = BIO_new_file(path, "r");

	if (bf == NULL)
	{
		g_critical("mconn-crypt: failed to open file %s", path);
		return FALSE;
	}

	RSA *rsa = NULL;

	rsa = PEM_read_bio_RSAPrivateKey(bf, NULL, NULL, NULL);

	BIO_free(bf);

	if (rsa == NULL)
	{
		g_critical("mconn-crypt: failed to read private key");
		return FALSE;
	}

	priv->key = rsa;

	return TRUE;
}

static gboolean __mconn_generate_key_at_path(const char *path)
{
	gboolean ret = FALSE;
	RSA *rsa = NULL;
	BIO *bf = NULL;
	BIGNUM *e = NULL;
	int res = 0;

	rsa = RSA_new();
	g_return_val_if_fail(rsa != NULL, FALSE);

	e = BN_new();
	if (e == NULL)
	{
		goto cleanup;
	}

	BN_set_word(e, RSA_3);

	if (RSA_generate_key_ex(rsa, 2048, e, NULL) != 1) {
		g_critical("mconn-crypt: failed to generate RSA key");
		goto cleanup;
	}

	bf = BIO_new_file(path, "w");
	if (bf == NULL)
	{
		g_error("mconn-crypt: failed to open file");
		goto cleanup;
	}

	if (PEM_write_bio_RSAPrivateKey(bf, rsa, NULL, NULL, 0, NULL, NULL) == 0)
	{
		g_critical("mconn-crypt: failed to private write key to file");
		goto cleanup;
	}

	ret = TRUE;

 cleanup:
	BN_free(e);
	RSA_free(rsa);
	BIO_free(bf);

	return ret;
}
