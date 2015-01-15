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

static void m_conn_crypt_dispose (GObject *object);
static void m_conn_crypt_finalize (GObject *object);
static gchar *__m_conn_get_public_key_as_pem(MConnCryptPrivate *priv);
static gboolean __m_conn_load_key(MConnCryptPrivate *priv, const char *path);
static gboolean __m_conn_generate_key_at_path(const char *path);

G_DEFINE_TYPE_WITH_PRIVATE (MConnCrypt, m_conn_crypt, G_TYPE_OBJECT);

static void
m_conn_crypt_class_init (MConnCryptClass *klass)
{
    GObjectClass *gobject_class = (GObjectClass *)klass;

    gobject_class->dispose = m_conn_crypt_dispose;
    gobject_class->finalize = m_conn_crypt_finalize;
}

static void
m_conn_crypt_init (MConnCrypt *self)
{
    g_debug("mconn-crypt: new instance");
    self->priv = m_conn_crypt_get_instance_private(self);
}

static void
m_conn_crypt_dispose (GObject *object)
{
    MConnCrypt *self = (MConnCrypt *)object;

    if (self->priv->key != NULL)
    {
        RSA_free(self->priv->key);
        self->priv->key = NULL;
    }

    G_OBJECT_CLASS (m_conn_crypt_parent_class)->dispose (object);
}

static void
m_conn_crypt_finalize (GObject *object)
{
    MConnCrypt *self = (MConnCrypt *)object;

    g_signal_handlers_destroy (object);
    G_OBJECT_CLASS (m_conn_crypt_parent_class)->finalize (object);
}

MConnCrypt *m_conn_crypt_new_for_key_path(const char *path)
{
    g_debug("mconn-crypt: new crypt for key %s", path);

    MConnCrypt *self = g_object_new(M_CONN_TYPE_CRYPT, NULL);

    if (g_file_test(path, G_FILE_TEST_EXISTS) == FALSE)
        __m_conn_generate_key_at_path(path);

    if (__m_conn_load_key(self->priv, path) == FALSE)
    {
        m_conn_crypt_unref(self);
        return NULL;
    }

    return self;
}

MConnCrypt * m_conn_crypt_ref(MConnCrypt *self)
{
    g_assert(IS_M_CONN_CRYPT(self));
    return M_CONN_CRYPT(g_object_ref(self));
}

void m_conn_crypt_unref(MConnCrypt *self)
{
    if (self != NULL)
    {
        g_assert(IS_M_CONN_CRYPT(self));
        g_object_unref(self);
    }
}

GBytes * m_conn_crypt_decrypt(MConnCrypt *self, GBytes *data, GError **err)
{

}

gchar *m_conn_crypt_get_public_key_pem(MConnCrypt *self)
{
    g_assert(IS_M_CONN_CRYPT(self));
    g_assert(self->priv);
    g_assert(self->priv->key);
    return __m_conn_get_public_key_as_pem(self->priv);
}

/**
 *
 */
static gchar *__m_conn_get_public_key_as_pem(MConnCryptPrivate *priv)
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
    g_debug("mconn-crypt: public key length: %l", data);
    g_assert(data != 0);
    g_assert(oss_pubkey != NULL);

    /* dup the key as buffer goes away with BIO */
    pubkey = g_strndup(oss_pubkey, data);

    BIO_set_close(bm, BIO_CLOSE);
    BIO_free(bm);

    return pubkey;
}

static gboolean __m_conn_load_key(MConnCryptPrivate *priv, const char *path)
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

static gboolean __m_conn_generate_key_at_path(const char *path)
{
    gboolean ret = TRUE;
    RSA *rsa = NULL;

    BIO *bf = BIO_new_file(path, "w");
    if (bf == NULL)
    {
        g_error("mconn-crypt: failed to open file");
        return FALSE;
    }

    rsa = RSA_generate_key(2048, RSA_3, NULL, NULL);

    if (PEM_write_bio_RSAPrivateKey(bf, rsa, NULL, NULL, 0, NULL, NULL) == 0)
    {
        g_critical("mconn-crypt: failed to private write key to file");
        ret = FALSE;
    }

    RSA_free(rsa);

    BIO_free(bf);

    return ret;
}
