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
	"io"
	"time"

	"github.com/pkg/errors"
)

var getId = func() uint64 {
	return uint64(time.Now().UnixNano() / 1000)
}

func Marshal(p *Packet) ([]byte, error) {
	b := &bytes.Buffer{}
	enc := NewEncoder(b)
	if err := enc.Encode(p); err != nil {
		return nil, err
	}
	return b.Bytes(), nil
}

type Encoder struct {
	w io.Writer
	j *json.Encoder
}

func NewEncoder(w io.Writer) *Encoder {
	return &Encoder{
		w: w,
		j: json.NewEncoder(w),
	}
}

type auxPacket struct {
	Packet
	Body interface{} `json:"body"`
}

func (e *Encoder) Encode(p *Packet) error {
	if p == nil {
		return errors.New("no packet")
	}

	if p.Type == "" {
		return errors.New("packet type not set")
	}

	id := p.Id
	if id == 0 {
		id = getId()
	}

	body := p.auxBody
	// encodes packet and appends a newline character
	err := e.j.Encode(auxPacket{
		Packet: Packet{
			Id:   id,
			Type: p.Type,
		},
		Body: body,
	})
	if err != nil {
		return errors.Wrap(err, "failed to encode body")
	}

	return nil
}
