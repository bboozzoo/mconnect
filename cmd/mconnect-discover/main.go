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

	"github.com/bboozzoo/mconnect/discovery"
	"github.com/bboozzoo/mconnect/logger"
)

var Stderr = os.Stderr

func main() {
	ctx := context.Background()
	ctx = logger.WithContext(ctx, logger.New())

	log := logger.FromContext(ctx)

	log.Printf("setting up listener")
	l, err := discovery.NewListener()
	if err != nil {
		fmt.Fprintf(Stderr, "error: failed to setup listener: %v\n",
			err)
		os.Exit(1)
	}

	for {
		log.Printf("receive wait")
		l.Receive(ctx)
	}
}
