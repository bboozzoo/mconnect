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
	"net"
)

const (
	// UDPPort is the UDP port used for discovery
	UDPPort = 1716
	// UDPPortOld is the UDP port used by older versions of the protocol
	UDPPortOld = 1714
	// TCPPortMin is the minimum TCP port number
	TCPPortMin = 1716

	PayloadTransferPortMin = 1739
)

var (
	// UDPDiscoveryAddr is the UDP address used for discovery
	UDPDiscoveryAddr = &net.UDPAddr{
		Port: UDPPort,
		IP:   net.ParseIP("255.255.255.255"),
	}
)
