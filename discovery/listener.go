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
package discovery

import (
	"context"
	"net"

	"github.com/bboozzoo/mconnect/logger"
)

type Listener struct {
	conn *net.UDPConn
}

func NewListener() (*Listener, error) {
	addr := net.UDPAddr{
		Port: 1714,
	}
	conn, err := net.ListenUDP("udp", &addr)
	if err != nil {
		return nil, err
	}

	listener := &Listener{
		conn: conn,
	}

	return listener, nil
}

func (l *Listener) Receive(ctx context.Context) {
	log := logger.FromContext(ctx)
	buf := make([]byte, 4096)
	count, addr, err := l.conn.ReadFromUDP(buf)
	if err != nil {
		log.Printf("listen failed: %v", err)
	}

	log.Printf("got %v bytes from %v", count, addr)
	log.Printf("data:\n%s", string(buf))
}
