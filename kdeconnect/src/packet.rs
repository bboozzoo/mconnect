// The MIT License (MIT)
//
// Copyright (c) 2020 Maciek Borzecki <maciek.borzecki@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

use serde::{Deserialize, Serialize};
use serde_json::value::{RawValue, Value};

// Identity type
const  IDENTITY: &str = "kdeconnect.identity";
// Pair type
const PAIR : &str = "kdeconnect.pair";

/// Represents an incoming packet. Only the type and ID deserialized. The
/// actual payload is handled higher up the stack.
#[derive(Deserialize)]
pub struct IncomingPacket<'a> {
    #[serde(rename = "type")]
    typ: String,
    id: String,
    #[serde(borrow)]
    body: &'a RawValue,
}

// Represents and outgoing packet.
#[derive(Serialize)]
pub struct Packet {
    #[serde(rename = "type")]
    typ: String,
    id: String,
    body: Value,
}

#[cfg(test)]
mod tests {
    use serde_json::{json, value::RawValue, value::Value, Result};

    #[test]
    fn packet_serialize_deserialize_simple() {
        let s = serde_json::to_string(&super::Packet {
            typ: "kdeconnect.foo".to_string(),
            id: "123".to_string(),
            body: json!("foobar foobar"),
        })
        .unwrap();

        let back: Result<super::IncomingPacket> = serde_json::from_str(&s);
        assert_eq!(back.is_ok(), true);

        let v = back.unwrap();
        assert_eq!(v.typ, "kdeconnect.foo");
        assert_eq!(v.id, "123");
        assert_eq!(v.body.get(), r#""foobar foobar""#)
    }

    #[test]
    fn packet_serialize_deserialize_complex() {
        let s = serde_json::to_string(&super::Packet {
            typ: "kdeconnect.foo".to_string(),
            id: "123".to_string(),
            body: json!({
                "foo": "bar",
                "baz": 2,
                "list": ["a", "b"],
            }),
        })
        .unwrap();

        let back: Result<super::IncomingPacket> = serde_json::from_str(&s);
        assert_eq!(back.is_ok(), true);

        let v = back.unwrap();
        assert_eq!(v.typ, "kdeconnect.foo");
        assert_eq!(v.id, "123");

        let bv: Value = serde_json::from_str(v.body.get()).unwrap();
        assert_eq!(
            bv,
            json!({
                "foo": "bar",
                "baz": 2,
                "list": ["a", "b"],
            })
        );
    }
}
