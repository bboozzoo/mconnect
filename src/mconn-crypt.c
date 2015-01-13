/* ex:ts=4:sw=4:sts=4:et */
/* -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/**
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
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

typedef struct _MConnCryptPrivate      MConnCryptPrivate;

/**
 * MConnCrypt:
 *
 * A simple wrapper for cypto operations.
 **/

struct _MConnCrypt
{
    GObject parent;
    MConnCryptPrivate *priv;
};

struct _MConnCryptPrivate
{
    RSA   *key;                 /* RSA key wrapper */
};

static void mconn_crypt_dispose (GObject *object);
static void mconn_crypt_finalize (GObject *object);
static gchar *__mconn_get_public_key_as_pem(MConnCryptPrivate *priv);
static gboolean __mconn_load_key(MConnCryptPrivate *priv, const char *path);
static gboolean __mconn_generate_key_at_path(const char *path);

G_DEFINE_TYPE_WITH_PRIVATE (MConnCrypt, mconn_crypt, G_TYPE_OBJECT);

static void
mconn_crypt_class_init (MConnCryptClass *klass)
{
    GObjectClass *gobject_class = (GObjectClass *)klass;

    gobject_class->dispose = mconn_crypt_dispose;
    gobject_class->finalize = mconn_crypt_finalize;
}

static void
mconn_crypt_init (MConnCrypt *self)
{
    self->priv = mconn_crypt_get_instance_private(self);
}

static void
mconn_crypt_dispose (GObject *object)
{
    MConnCrypt *self = (MConnCrypt *)object;

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
    MConnCrypt *self = (MConnCrypt *)object;

    g_signal_handlers_destroy (object);
    G_OBJECT_CLASS (mconn_crypt_parent_class)->finalize (object);
}

MConnCrypt *mconn_crypt_new_for_key_path(const char *path)
{
    g_debug("new crypt for key %s", path);

    MConnCrypt *self = g_object_new(MCONN_TYPE_CRYPT, NULL);

    if (g_file_test(path, G_FILE_TEST_EXISTS) == FALSE)
        __mconn_generate_key_at_path(path);

    if (__mconn_load_key(self->priv, path) == FALSE)
    {
        mconn_crypt_unref(self);
        return NULL;
    }

    return self;
}

MConnCrypt * mconn_crypt_ref(MConnCrypt *self)
{
    g_assert(IS_MCONN_CRYPT(self));
    return MCONN_CRYPT(g_object_ref(self));
}

void mconn_crypt_unref(MConnCrypt *self)
{
    if (self != NULL)
    {
        g_assert(IS_MCONN_CRYPT(self));
        g_object_unref(self);
    }
}

GBytes * mconn_crypt_decrypt(MConnCrypt *self, GBytes *data, GError **err)
{

}

gchar *mconn_crypt_get_public_key_pem(MConnCrypt *self)
{
    g_assert(IS_MCONN_CRYPT(self));
    g_assert(self->priv);

    return __mconn_get_public_key_as_pem(self->priv);
}

/**
 *
 */
static gchar *__mconn_get_public_key_as_pem(MConnCryptPrivate *priv)
{
    gchar *pubkey = NULL;

    /* memory IO  */
    BIO *bm = BIO_new(BIO_s_mem());

    /* generate PEM */
    PEM_write_bio_RSAPublicKey(bm, priv->key);

    /* get PEM as text */
    char *oss_pubkey = NULL;
    long data = BIO_get_mem_data(bm, &oss_pubkey);
    g_assert(data != 0);
    g_assert(oss_pubkey != NULL);

    /* dup the key as buffer goes away with BIO */
    pubkey = g_strdup(oss_pubkey);

    BIO_set_close(bm, BIO_CLOSE);
    BIO_free(bm);

    return pubkey;
}

static gboolean __mconn_load_key(MConnCryptPrivate *priv, const char *path)
{
    if (g_file_test(path, G_FILE_TEST_EXISTS) == FALSE)
    {
        g_critical("key file %s does not exist", path);
        return FALSE;
    }

    g_debug("loading key from %s", path);

    BIO *bf = BIO_new_file(path, "r");

    if (bf == NULL)
    {
        g_critical("failed to open file %s", path);
        return FALSE;
    }

    RSA *rsa = NULL;

    rsa = PEM_read_bio_RSAPrivateKey(bf, NULL, NULL, NULL);

    BIO_free(bf);

    if (rsa == NULL)
    {
        g_critical("failed to read private key");
        return FALSE;
    }

    priv->key = rsa;

    return TRUE;
}

static gboolean __mconn_generate_key_at_path(const char *path)
{
    gboolean ret = TRUE;
    RSA *rsa = NULL;

    BIO *bf = BIO_new_file(path, "w");
    if (bf == NULL)
    {
        g_error("failed to open file");
        return FALSE;
    }

    rsa = RSA_generate_key(2048, RSA_3, NULL, NULL);

    if (PEM_write_bio_RSAPrivateKey(bf, rsa, NULL, NULL, 0, NULL, NULL) == 0)
    {
        g_critical("failed to private write key to file");
        ret = FALSE;
    }

    RSA_free(rsa);

    BIO_free(bf);

    return ret;
}
