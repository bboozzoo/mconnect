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
package config

import (
	"fmt"

	"gopkg.in/ini.v1"
)

type config struct {
	Main mainConfig
}

type mainConfig struct {
	Debug   bool
	Devices []string
}

type deviceInfo struct {
	Name    string
	Type    string
	Allowed bool
}

func Load(from string) error {
	_, err := ini.Load(from)
	if err != nil {
		return fmt.Errorf("cannot load config file: %v", err)
	}
	return nil
}