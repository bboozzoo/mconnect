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
#ifndef __MCONN_CRYPT_H__
#define __MCONN_CRYPT_H__

#include <glib-object.h>


G_BEGIN_DECLS

#define MCONN_TYPE_CRYPT                        \
   (mconn_crypt_get_type())
#define MCONN_CRYPT(obj)                                                \
   (G_TYPE_CHECK_INSTANCE_CAST ((obj),                                  \
                                MCONN_TYPE_CRYPT,                       \
                                MConnCrypt))
#define MCONN_CRYPT_CLASS(klass)                                        \
   (G_TYPE_CHECK_CLASS_CAST ((klass),                                   \
                             MCONN_TYPE_CRYPT,                          \
                             MConnCryptClass))
#define IS_MCONN_CRYPT(obj)                                             \
   (G_TYPE_CHECK_INSTANCE_TYPE ((obj),                                  \
                                MCONN_TYPE_CRYPT))
#define IS_MCONN_CRYPT_CLASS(klass)                                     \
   (G_TYPE_CHECK_CLASS_TYPE ((klass),                                   \
                             MCONN_TYPE_CRYPT))
#define MCONN_CRYPT_GET_CLASS(obj)                                      \
   (G_TYPE_INSTANCE_GET_CLASS ((obj),                                   \
                               MCONN_TYPE_CRYPT,                        \
                               MConnCryptClass))

typedef struct _MConnCrypt      MConnCrypt;
typedef struct _MConnCryptClass MConnCryptClass;
typedef struct _MConnCryptPrivate      MConnCryptPrivate;

struct _MConnCryptClass
{
    GObjectClass parent_class;
};

struct _MConnCrypt
{
    GObject parent;
    MConnCryptPrivate *priv;
};

GType mconn_crypt_get_type (void) G_GNUC_CONST;

MConnCrypt *mconn_crypt_new_for_key_path(const char *path);
void mconn_crypt_unref(MConnCrypt *crypt);
GBytes * mconn_crypt_decrypt(MConnCrypt *crypt, GBytes *data, GError **err);
gchar * mconn_crypt_get_public_key_pem(MConnCrypt *crypt);
G_END_DECLS

#endif /* __MCONN_CRYPT_H__ */
