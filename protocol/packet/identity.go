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
package packet

import (
	"encoding/json"
	"fmt"
)

type Identity struct {
	DeviceId             string   `json:"deviceId"`
	DeviceName           string   `json:"deviceName"`
	DeviceType           string   `json:"deviceType"`
	ProtocolVersion      uint     `json:"protocolVersion"`
	IncomingCapabilities []string `json:"incomingCapabilities"`
	OutgoingCapabilities []string `json:"outgoingCapabilities"`
	TcpPort              uint     `json:"tcpPort"`
}

func (p *Packet) AsIdentity() (*Identity, error) {
	if p.Type != "kdeconnect.identity" {
		return nil, fmt.Errorf("not an identity packet, unexpected type %q", p.Type)
	}
	var identity Identity
	if err := json.Unmarshal(p.Body, &identity); err != nil {
		return nil, err
	}
	return &identity, nil
}
