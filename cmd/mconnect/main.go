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
	"path/filepath"

	"github.com/jessevdk/go-flags"

	"github.com/bboozzoo/mconnect/config"
	"github.com/bboozzoo/mconnect/daemon"
	"github.com/bboozzoo/mconnect/logger"
	uflags "github.com/bboozzoo/mconnect/utils/flags"
)

var (
	Stderr = os.Stderr
	Stdout = os.Stdout
)

func mconnectConfigFile() (string, error) {
	cdir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("cannot identify user config dir: %v", err)
	}
	return filepath.Join(cdir, "mconnect", "mconnect.conf"), nil
}

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
	if err := run(ctx); err != nil {
		fmt.Fprintf(Stderr, "%v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	configFile, err := mconnectConfigFile()
	if err != nil {
		return err
	}
	if err := config.Load(configFile); err != nil {
		return err
	}

	d := daemon.New()
	d.Run(ctx)
	return nil
}
