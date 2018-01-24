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
package packet_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/bboozzoo/mconnect/protocol/packet"
)

func TestUnmarshal(t *testing.T) {
	var p packet.Packet
	err := packet.Unmarshal([]byte(`foobar`), &p)
	assert.Error(t, err)

	p = packet.Packet{}
	err = packet.Unmarshal([]byte(`{}`), &p)
	assert.Error(t, err)

	p = packet.Packet{}
	err = packet.Unmarshal([]byte(`{"id": 123, "type": "foo","body":{}}`), &p)
	assert.NoError(t, err)
	assert.Equal(t, p, packet.Packet{
		Id:   uint64(123),
		Type: "foo",
		Body: []byte("{}"),
	})
}
