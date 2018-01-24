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
	"time"
)

var getId = func() uint64 {
	return uint64(time.Now().UnixNano() / 1000)
}

func Marshal(p *Packet) ([]byte, error) {
	if p == nil {
		return nil, fmt.Errorf("no packet")
	}

	if p.Type == "" {
		return nil, fmt.Errorf("packet type not set")
	}

	body, err := json.Marshal(p.auxBody)
	if err != nil {
		return nil, fmt.Errorf("failed to encode body: %v", err)
	}
	id := p.Id
	if id == 0 {
		id = getId()
	}
	data, err := json.Marshal(Packet{
		Id:   id,
		Type: p.Type,
		Body: body,
	})
	if err != nil {
		return nil, err
	}

	return append(data, '\n'), nil
}
