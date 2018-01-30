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
	"time"

	"github.com/jessevdk/go-flags"

	"github.com/bboozzoo/mconnect/discovery"
	"github.com/bboozzoo/mconnect/logger"
	"github.com/bboozzoo/mconnect/protocol/packet"
	uflags "github.com/bboozzoo/mconnect/utils/flags"
)

var (
	Stderr = os.Stderr
	Stdout = os.Stdout
)

func main() {
	var opts struct {
		Debug bool `short:"d" long:"debug" description:"Show debugging information"`
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

	log.Infof("setting up listener")
	l, err := discovery.NewListener()
	if err != nil {
		fmt.Fprintf(Stderr, "error: failed to setup listener: %v\n",
			err)
		os.Exit(1)
	}

	hostname, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(Stderr, "error: failed to obtain hostname: %v\n",
			err)
		os.Exit(1)
	}

	go func() {
		for {
			err := discovery.Announce(ctx, packet.Identity{
				DeviceId:        "mconnect-" + hostname,
				DeviceName:      hostname,
				DeviceType:      "computer",
				ProtocolVersion: 7,
				TcpPort:         1716,
			})
			if err != nil {
				log.Errorf("failed to self announce: %v", err)
			}
			time.Sleep(5 * time.Second)
		}
	}()

	devices := map[string]*discovery.Discovery{}

	for {
		log.Info("receive wait")
		d, err := l.Receive(ctx)
		if err != nil {
			log.Warning("failed to receive identity packet: %v", err)
			continue
		}

		log.Infof("discovered a device at %s packet: %v",
			d.From, d.Identity)
		if _, ok := devices[d.Identity.DeviceId]; !ok {
			devices[d.Identity.DeviceId] = d
			fmt.Fprintf(Stdout, " * %q (ID: %v) %v:%v\n",
				d.Identity.DeviceName,
				d.Identity.DeviceId,
				d.From.IP, d.Identity.TcpPort)
		}
	}
}
