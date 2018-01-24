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
package dirs

import (
	"os/user"
	"path"
)

var userHome string

func UserHome() string {
	if userHome == "" {
		user, _ := user.Current()
		if user != nil {
			userHome = user.HomeDir
		}
	}
	return userHome
}

func UserCache() string {
	return path.Join(UserHome(), ".cache", "mconnect")
}

func UserConfig() string {
	return path.Join(UserHome(), ".config", "mconnect")
}

func UserData() string {
	return path.Join(UserHome(), ".local", "share", "mconnect")
}
