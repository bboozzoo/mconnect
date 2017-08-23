/*
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
 * Author: Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */
#ifndef __M_CONN_CRYPT_H__
#define __M_CONN_CRYPT_H__

#include <glib-object.h>
#include <glib.h>
#include <glib/gbytes.h>

G_BEGIN_DECLS

#define MCONN_TYPE_CRYPT						\
   (mconn_crypt_get_type())
#define MCONN_CRYPT(obj)												\
   (G_TYPE_CHECK_INSTANCE_CAST ((obj),									\
								MCONN_TYPE_CRYPT,						\
								MconnCrypt))
#define MCONN_CRYPT_CLASS(klass)										\
   (G_TYPE_CHECK_CLASS_CAST ((klass),									\
							 MCONN_TYPE_CRYPT,							\
							 MconnCryptClass))
#define IS_MCONN_CRYPT(obj)												\
   (G_TYPE_CHECK_INSTANCE_TYPE ((obj),									\
								MCONN_TYPE_CRYPT))
#define IS_MCONN_CRYPT_CLASS(klass)										\
   (G_TYPE_CHECK_CLASS_TYPE ((klass),									\
							 MCONN_TYPE_CRYPT))
#define MCONN_CRYPT_GET_CLASS(obj)										\
   (G_TYPE_INSTANCE_GET_CLASS ((obj),									\
							   MCONN_TYPE_CRYPT,						\
							   MconnCryptClass))

typedef struct _MconnCrypt		MconnCrypt;
typedef struct _MconnCryptClass MconnCryptClass;
struct _MconnCryptClass
{
	GObjectClass parent_class;
};

GType mconn_crypt_get_type (void) G_GNUC_CONST;

/**
 * mconn_crypt_new_for_key_path: (constructor)
 * @path: key path
 *
 * Returns: (transfer full): new object
 */
MconnCrypt *mconn_crypt_new_for_key_path(const char *path);

/**
 * mconn_crypt_unref:
 * @crypt: crypt object
 */
void mconn_crypt_unref(MconnCrypt *crypt);

/**
 * mconn_crypt_ref:
 * @crypt: crypt object
 *
 * Take reference to crypt object
 * Returns: (transfer none): reffed object
 */
MconnCrypt *mconn_crypt_ref(MconnCrypt *crypt);

/**
 * mconn_crypt_decrypt:
 * @crypt: crypt object
 * @data: (type GBytes): data
 * @error: return location for a GError or NULL
 *
 * Returns: (transfer full): a new #GByteArray with decoded data
 */
GByteArray * mconn_crypt_decrypt(MconnCrypt *crypt, GBytes *data, GError **error);

/**
 * mconn_crypt_get_public_key_pem:
 * @crypt: crypt object
 *
 * Returns: (transfer full): allocated string with public key in PEM format
 */
gchar * mconn_crypt_get_public_key_pem(MconnCrypt *crypt);

G_END_DECLS

#endif /* __MCONN_CRYPT_H__ */
