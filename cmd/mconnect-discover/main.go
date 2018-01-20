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
