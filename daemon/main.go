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
package daemon

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/bboozzoo/mconnect/discovery"
	"github.com/bboozzoo/mconnect/logger"
	"github.com/bboozzoo/mconnect/mconnect"
)

type Daemon struct{}

func New() *Daemon {
	return &Daemon{}
}

func (d *Daemon) Run(ctx context.Context) error {
	log := logger.FromContext(ctx)

	sigChan := make(chan os.Signal)

	mgr := mconnect.DeviceManager{}

	l, err := discovery.NewListener()
	if err != nil {
		return fmt.Errorf("cannot create listener: %v", err)
	}

	ctx, cancel := context.WithCancel(ctx)
	l.WaitForDevices(ctx)

	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	run := true
	for run {
		select {
		case dev := <-l.Device(ctx):
			if dev != nil {
				log.Debugf("device: %v", dev)
				mgr.AddDiscoveredDevice(dev.Identity, dev.From.IP.String())
			}
		case sig := <-sigChan:
			log.Infof("exiting on %v signal", sig)
			cancel()
			mgr.Close()
			run = false
		}
	}
	l.Done()
	return nil
}
