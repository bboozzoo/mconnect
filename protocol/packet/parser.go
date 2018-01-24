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
	"bytes"
	"encoding/json"
	"fmt"
)

func Unmarshal(data []byte, p *Packet) error {
	if len(data) == 0 {
		return fmt.Errorf("no data")
	}

	if p == nil {
		return fmt.Errorf("no packet")
	}

	if idx := bytes.LastIndexByte(data, '\n'); idx != -1 {
		data = data[0:idx]
	}
	if err := json.Unmarshal(data, p); err != nil {
		return err
	}

	if p.Id == uint64(0) || p.Type == "" || p.Body == nil {
		return fmt.Errorf("packet incomplete, missing id, type or body")
	}
	return nil
}
