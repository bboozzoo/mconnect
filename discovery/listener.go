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
	"errors"
	"fmt"
	"net"

	"github.com/bboozzoo/mconnect/logger"
	"github.com/bboozzoo/mconnect/protocol"
	"github.com/bboozzoo/mconnect/protocol/packet"
)

type Listener struct {
	conn   *net.UDPConn
	devC   chan *Discovery
	closeC chan struct{}
}

func NewListener() (*Listener, error) {
	conn, err := net.ListenUDP("udp", protocol.UDPDiscoveryAddr)
	if err != nil {
		return nil, err
	}

	listener := &Listener{
		conn: conn,
	}

	return listener, nil
}

// Discovery conveys the received discovery information
type Discovery struct {
	// Packet is the original packet received
	Packet *packet.Packet
	// Identity is the parsed identity data
	Identity *packet.Identity
	// From is the address the packet was received from
	From *net.UDPAddr
}

// Receive blocks waiting to receive a discovery packet. Once received, it will
// parse the packet and return a result.
func (l *Listener) Receive(ctx context.Context) (*Discovery, error) {
	log := logger.FromContext(ctx)
	buf := make([]byte, 4096)
	count, addr, err := l.conn.ReadFromUDP(buf)
	if err != nil {
		return nil, fmt.Errorf("cannot to receive packet: %w", err)
	}
	log.Debugf("got %v bytes from %v", count, addr)
	log.Tracef("data:\n%s", string(buf))
	var p packet.Packet
	if err := packet.Unmarshal(buf, &p); err != nil {
		return nil, fmt.Errorf("cannot parse packet: %w", err)
	}
	identity, err := p.AsIdentity()
	if err != nil {
		return nil, fmt.Errorf("cannot parse as identity packet: %w", err)
	}
	discovery := &Discovery{
		Packet:   &p,
		Identity: identity,
		From:     addr,
	}
	return discovery, nil
}

func (l *Listener) WaitForDevices(ctx context.Context) {
	l.closeC = make(chan struct{})
	l.devC = make(chan *Discovery, 1)
	log := logger.FromContext(ctx)
	go func() {
		for {
			discovery, err := l.Receive(ctx)
			if err != nil {
				if errors.Is(err, net.ErrClosed) {
					break
				}
				log.Errorf("discovery failed: %v", err)
				continue
			}
			l.devC <- discovery
		}
		log.Debugf("discovery done")
		close(l.closeC)
	}()

	go func() {
		<-ctx.Done()
		l.conn.Close()
	}()
}

func (l *Listener) Device(ctx context.Context) <-chan *Discovery {
	if l.devC == nil {
		logger.FromContext(ctx).Panicf("cannot call Device without Wait first")
	}
	return l.devC
}

func (l *Listener) Done() {
	if l.closeC != nil {
		<-l.closeC
	}
}
