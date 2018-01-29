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
package flags

import (
	"fmt"
	"os"

	"github.com/jessevdk/go-flags"
)

func IsErrHelp(err error) bool {
	ferr, ok := err.(*flags.Error)
	return ok && ferr.Type == flags.ErrHelp
}

func HandleFlagsError(err error) {
	if err == nil {
		panic(fmt.Sprintf("expected an error, got %v", err))
	}

	if IsErrHelp(err) {
		os.Exit(0)
	}
	os.Exit(1)

}
