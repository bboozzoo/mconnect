//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
package protocol

import (
	"context"
	"crypto/tls"
	"net"

	"github.com/pkg/errors"

	"github.com/bboozzoo/mconnect/logger"
	"github.com/bboozzoo/mconnect/protocol/packet"
)

type Connection struct {
	conn net.Conn
}

type Configuration struct {
	Cert     *tls.Certificate
	Identity *packet.Identity
}

func Dial(ctx context.Context, where string, conf *Configuration) (*Connection, error) {
	log := logger.FromContext(ctx)

	dialer := net.Dialer{}
	conn, err := dialer.DialContext(ctx, "tcp", where)
	if err != nil {
		return nil, errors.Wrapf(err, "failed to dial %s", where)
	}
	log.Debugf("connected to %v", conn.RemoteAddr())

	e := packet.NewEncoder(conn)
	if err := e.Encode(packet.NewIdentity(conf.Identity)); err != nil {
		return nil, errors.Wrapf(err, "failed to send identity")
	}

	log.Debugf("identity sent")

	return &Connection{conn: conn}, nil
}

func (c *Connection) Close() error {
	if c.conn != nil {
		c.conn.Close()
	}
	return nil
}
