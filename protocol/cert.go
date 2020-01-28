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
package protocol

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"time"
)

type DeviceCertificate struct {
	key  *ecdsa.PrivateKey
	cert []byte
}

func (d *DeviceCertificate) TLSCertificate() *tls.Certificate {
	return &tls.Certificate{
		PrivateKey:  d.key,
		Certificate: [][]byte{d.cert},
	}
}

// GenerateDeviceCertificate returns a device certificate
func GenerateDeviceCertificate(entity string) (*DeviceCertificate, error) {
	limit := big.Int{}
	limit.Lsh(big.NewInt(1), 128)
	serial, err := rand.Int(rand.Reader, &limit)
	if err != nil {
		return nil, err
	}

	priv, err := ecdsa.GenerateKey(elliptic.P384(), rand.Reader)
	if err != nil {
		return nil, err
	}

	startTime := time.Now()
	// 10 years from now
	expireTime := startTime.AddDate(10, 0, 0)

	template := x509.Certificate{
		SerialNumber: serial,
		Subject: pkix.Name{
			CommonName:         entity,
			Organization:       []string{"mconnect"},
			OrganizationalUnit: []string{"mconnect"},
		},
		NotBefore:             startTime,
		NotAfter:              expireTime,
		BasicConstraintsValid: true,
	}
	selfSign := template
	cert, err := x509.CreateCertificate(rand.Reader, &template, &selfSign,
		&priv.PublicKey, priv)
	if err != nil {
		return nil, err
	}
	devcert := &DeviceCertificate{
		key:  priv,
		cert: cert,
	}
	return devcert, nil
}
