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

	"github.com/pkg/errors"

	"github.com/bboozzoo/mconnect/protocol/packet"
)

func Announce(ctx context.Context, identity packet.Identity) error {
	p := packet.New("kdeconnect.identity", identity)
	data, err := packet.Marshal(p)
	if err != nil {
		return errors.Wrapf(err, "failed to marshal packet")
	}

	addr := net.UDPAddr{
		Port: 1716,
		IP:   net.ParseIP("255.255.255.255"),
	}
	c, err := net.DialUDP("udp", nil, &addr)
	if err != nil {
		return errors.Wrapf(err, "failed to open UDP socket")
	}
	defer c.Close()

	_, err = c.Write(data)
	if err != nil {
		return errors.Wrapf(err, "failed to send identity packet")
	}
	return nil
}
