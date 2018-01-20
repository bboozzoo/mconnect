package logger

import (
	"os"

	"github.com/Sirupsen/logrus"
)

var log *logrus.Logger

func init() {
	log = &logrus.Logger{
		Out: os.Stderr,
		Formatter: &logrus.TextFormatter{
			FullTimestamp: true,
		},
		Hooks: make(logrus.LevelHooks),
		Level: logrus.DebugLevel,
	}
}

func New() Logger {
	return log
}
