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
	"io"

	"github.com/pkg/errors"
)

func Unmarshal(data []byte, p *Packet) error {
	return NewDecoder(bytes.NewBuffer(data)).Decode(p)
}

type Decoder struct {
	r io.Reader
	j *json.Decoder
}

func NewDecoder(r io.Reader) *Decoder {
	return &Decoder{
		r: r,
		j: json.NewDecoder(r),
	}
}

func (d *Decoder) Decode(p *Packet) error {
	if p == nil {
		return fmt.Errorf("no packet")
	}

	if err := d.j.Decode(p); err != nil {
		return errors.Wrap(err, "failed to decode body")
	}

	if p.Id == uint64(0) || p.Type == "" || p.Body == nil {
		return fmt.Errorf("packet incomplete, missing id, type or body")
	}
	return nil
}
