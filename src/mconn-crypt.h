/* ex:ts=4:sw=4:sts=4:et */
/* -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
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
 * Author: Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */
#ifndef __M_CONN_CRYPT_H__
#define __M_CONN_CRYPT_H__

#include <glib-object.h>
#include <glib.h>
#include <glib/gbytes.h>

G_BEGIN_DECLS

#define M_CONN_TYPE_CRYPT                        \
   (m_conn_crypt_get_type())
#define M_CONN_CRYPT(obj)                                                \
   (G_TYPE_CHECK_INSTANCE_CAST ((obj),                                  \
                                M_CONN_TYPE_CRYPT,                       \
                                MConnCrypt))
#define M_CONN_CRYPT_CLASS(klass)                                        \
   (G_TYPE_CHECK_CLASS_CAST ((klass),                                   \
                             M_CONN_TYPE_CRYPT,                          \
                             MConnCryptClass))
#define IS_M_CONN_CRYPT(obj)                                             \
   (G_TYPE_CHECK_INSTANCE_TYPE ((obj),                                  \
                                M_CONN_TYPE_CRYPT))
#define IS_M_CONN_CRYPT_CLASS(klass)                                     \
   (G_TYPE_CHECK_CLASS_TYPE ((klass),                                   \
                             M_CONN_TYPE_CRYPT))
#define M_CONN_CRYPT_GET_CLASS(obj)                                      \
   (G_TYPE_INSTANCE_GET_CLASS ((obj),                                   \
                               M_CONN_TYPE_CRYPT,                        \
                               MConnCryptClass))

typedef struct _MConnCrypt      MConnCrypt;
typedef struct _MConnCryptClass MConnCryptClass;
struct _MConnCryptClass
{
    GObjectClass parent_class;
};

GType m_conn_crypt_get_type (void) G_GNUC_CONST;

/**
 * m_conn_crypt_new_for_key_path: (constructor)
 * @path: key path
 *
 * Returns: (transfer full): new object
 */
MConnCrypt *m_conn_crypt_new_for_key_path(const char *path);

/**
 * m_conn_crypt_unref:
 * @crypt: crypt object
 */
void m_conn_crypt_unref(MConnCrypt *crypt);

/**
 * m_conn_crypt_ref:
 * @crypt: crypt object
 *
 * Take reference to crypt object
 * Returns: (transfer none): reffed object
 */
MConnCrypt *m_conn_crypt_ref(MConnCrypt *crypt);

/**
 * m_conn_crypt_decrypt:
 * @crypt: crypt object
 * @data: (type GBytes): data
 * @error: return location for a GError or NULL
 *
 * Returns: (transfer full): a new #GBytes with decoded data
 */
GBytes * m_conn_crypt_decrypt(MConnCrypt *crypt, GBytes *data, GError **error);

/**
 * m_conn_crypt_get_public_key_pem:
 * @crypt: crypt object
 *
 * Returns: (transfer full): allocated string with public key in PEM format
 */
gchar * m_conn_crypt_get_public_key_pem(MConnCrypt *crypt);

G_END_DECLS

#endif /* __M_CONN_CRYPT_H__ */
