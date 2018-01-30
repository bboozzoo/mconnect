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
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jessevdk/go-flags"

	"github.com/bboozzoo/mconnect/logger"
	"github.com/bboozzoo/mconnect/protocol"
	"github.com/bboozzoo/mconnect/protocol/packet"
	uflags "github.com/bboozzoo/mconnect/utils/flags"
)

var (
	Stderr = os.Stderr
	Stdout = os.Stdout
)

func main() {
	var opts struct {
		Debug   bool   `short:"d" long:"debug" description:"Show debugging information"`
		Address string `short:"a" long:"address" description:"Address of remote device"`
	}

	_, err := flags.ParseArgs(&opts, os.Args)
	if err != nil {
		uflags.HandleFlagsError(err)
	}

	ctx := context.Background()
	ctx = logger.WithContext(ctx, logger.New())

	log := logger.FromContext(ctx)
	log.SetLevel(logger.ErrorLevel)
	if opts.Debug {
		log.SetLevel(logger.DebugLevel)
	}

	hostname, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(Stderr, "error: failed to obtain hostname: %v\n",
			err)
		os.Exit(1)
	}

	conf := protocol.Configuration{
		Identity: &packet.Identity{
			DeviceId:        "mconnect-" + hostname,
			DeviceName:      hostname,
			DeviceType:      "computer",
			ProtocolVersion: 7,
			TcpPort:         1716,
		},
	}
	conn, err := protocol.Dial(ctx, opts.Address, &conf)
	if err != nil {
		log.Errorf("connection failed: %v", err)
		os.Exit(1)
	}
	defer conn.Close()
}
