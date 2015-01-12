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
#include <glib.h>
#include "mconn-crypt.h"

static void test_simple(void)
{
    g_remove("/tmp/test.key");
    /* we made sure that file is removed */
    g_assert_false(g_file_test("/tmp/test.key", G_FILE_TEST_EXISTS));

    MConnCrypt *cr = mconn_crypt_new_for_key_path("/tmp/test.key");
    g_assert_nonnull(cr);
    g_assert_true(g_file_test("/tmp/test.key", G_FILE_TEST_EXISTS));

    gchar *pubkey1 = mconn_crypt_get_public_key_pem(cr);

    mconn_crypt_unref(cr);
    /* file should still exit */
    g_assert_true(g_file_test("/tmp/test.key", G_FILE_TEST_EXISTS));

    cr = mconn_crypt_new_for_key_path("/tmp/test.key");
    /* key should have been loaded */
    g_assert_nonnull(cr);
    g_assert_true(g_file_test("/tmp/test.key", G_FILE_TEST_EXISTS));

    gchar *pubkey2 = mconn_crypt_get_public_key_pem(cr);

    mconn_crypt_unref(cr);

    g_assert_cmpstr(pubkey1, ==, pubkey2);
}

int main(int argc, char *argv[])
{
    g_test_init(&argc, &argv, NULL);

    g_test_add_func("/mconn-crypt/init", test_simple);

    return g_test_run();
}
