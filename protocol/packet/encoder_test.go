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

func TestMarshal(t *testing.T) {
	data, err := packet.Marshal(nil)
	assert.Error(t, err)

	data, err = packet.Marshal(&packet.Packet{})
	assert.Error(t, err)

	exp := `{"id":123,"type":"foo","body":null}` + "\n"
	p := packet.New("foo", nil)
	p.Id = 123
	data, err = packet.Marshal(p)
	assert.NoError(t, err)
	assert.Equal(t, []byte(exp), data)

	exp = `{"id":123,"type":"foo","body":{}}` + "\n"
	p = packet.New("foo", map[int]int{})
	p.Id = 123
	data, err = packet.Marshal(p)
	assert.NoError(t, err)
	assert.Equal(t, []byte(exp), data)

	restore := packet.MockGetId(func() uint64 {
		return uint64(889911)
	})
	defer restore()

	exp = `{"id":889911,"type":"foo","body":{}}` + "\n"
	data, err = packet.Marshal(packet.New("foo", map[int]int{}))
	assert.NoError(t, err)
	assert.Equal(t, []byte(exp), data)
}
