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
use std::net::{SocketAddr, UdpSocket};

use log;

use kdeconnect::port;

pub fn discovery() -> Result<(), String> {
    let addr = SocketAddr::from(([0, 0, 0, 0], port::DISCOVERY));
    let s = UdpSocket::bind(addr)
        .or_else(|e| return Err(format!("cannot bind discovery socket: {}", e)))?;

    log::debug!("discovery bound to {}", addr);

    let mut buf = [0; 4096];
    let (got, from) = s
        .recv_from(&mut buf)
        .or_else(|e| return Err(format!("cannot receive data from socket: {}", e)))?;

    log::debug!("got {} bytes from from {}", got, from);
    log::debug!("got: {}", String::from_utf8_lossy(&buf[..got]));

    Ok(())
}
