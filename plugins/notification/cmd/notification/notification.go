package main

import (
	"context"
	"os"

	"github.com/godbus/dbus"

	"github.com/bboozzoo/mconnect/logger"
)

func main() {
	ctx := context.Background()
	ctx = logger.WithContext(ctx, logger.New())

	log := logger.FromContext(ctx)

	conn, err := dbus.SessionBus()
	if err != nil {
		log.Errorf("failed to connect to session bys: %v")
		os.Exit(1)
	}
	defer conn.Close()

	o := conn.Object("org.freedesktop.Notifications",
		dbus.ObjectPath("/org/freedesktop/Notifications"))
	c := o.Call("org.freedesktop.Notifications.Notify", 0, "", uint32(0),
		"", "Test",
		"This is a test of the DBus bindings for go.",
		[]string{},
		map[string]dbus.Variant{}, int32(5000))
	if c.Err != nil {
		log.Panicf("call failed %v", c.Err)
	}
}
