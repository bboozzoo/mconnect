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
package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

type logger struct {
	logrus.Logger
}

var log *logger

func init() {
	log = &logger{
		Logger: logrus.Logger{
			Out: os.Stderr,
			Formatter: &logrus.TextFormatter{
				FullTimestamp: true,
			},
			Hooks: make(logrus.LevelHooks),
			Level: logrus.DebugLevel,
		},
	}
}

func New() Logger {
	return log
}

func (l *logger) SetLevel(level Level) {
	l.Logger.SetLevel(logrus.Level(level))
}
