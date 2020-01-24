package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"fmt"
	"net"
	// "strings"
)

var (
	// End  = []byte{0x03, 0x06}
	// End = []byte{0x06, 0x41, 0x82}
	End = []byte{0xde, 0xde}
)

func SplitFrames(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}

	// // start := bytes.Index(data, []byte{0x06, 0x41, 0x82})
	// start := bytes.Index(data, []byte{0x06, 0x41, 0x82})
	// if start == -1 {
	//   advance := Max(len(data)-3, 0)
	//   fmt.Printf("no start, dropped: %+v\n", data[:advance])
	//   return advance, nil, nil
	//
	// }
	// fmt.Printf("found start: %d %d\n", len(data), start)

	// end := bytes.Index(data, []byte{0x03, 0x06, 0x41})
	end := bytes.Index(data, End)

	if end == -1 {
		return 0, nil, nil
	} else {
		// fmt.Printf("found end: %d %d %d %d\n", len(data), start, end, len(data[start:end]))
		return end + len(End), data[:end+len(End)], nil
	}

	if atEOF {
		fmt.Printf("eof, dropped: %+v\n", data)
		return len(data), data, nil
	}

	return
}

type Frame struct {
	start []byte
	data  []byte
	crc   uint16
	end   []byte
}

func (f *Frame) from_bytes(data []byte) error {
	// if bytes.Index(data, []byte{0x06, 0x41, 0x82}) != 0 || bytes.Index(data, []byte{0x03, 0x06, 0x41}) != len(data)-3 {
	//   return fmt.Errorf("invalid frame")
	// }
	if bytes.Index(data, End) != len(data)-len(End) {
		return fmt.Errorf("invalid frame, no end")
	}
	if len(data) < 4+2+len(End) {
		return fmt.Errorf("invalid frame, to short")
	}

	f.start = data[:4]
	f.data = data[4 : len(data)-len(End)-2]
	f.crc = binary.BigEndian.Uint16(data[len(data)-len(End)-2 : len(data)-len(End)])
	f.end = data[len(data)-len(End):]
	// fmt.Printf("\nframe: %+v\n", f)
	// fmt.Printf("data: %+X\n", data)

	if Kermit(f.data) != f.crc {
		// fmt.Printf("%X, %X\n", f.data, f.crc)
		return fmt.Errorf("invalid CRC: %X %X %X", f.data, f.crc, Kermit(f.data))
	}

	return nil
}

func Kermit(byteArray []byte) uint16 {
	var crc uint16
	for i := 0; i < len(byteArray); i++ {
		b := uint16(byteArray[i])
		q := (crc ^ b) & 0x0f
		crc = (crc >> 4) ^ (q * 0x1081)
		q = (crc ^ (b >> 4)) & 0xf
		crc = (crc >> 4) ^ (q * 0x1081)
	}
	return (crc >> 8) ^ (crc << 8)
}

func Max(x, y int) int {
	if x > y {
		return x
	}
	return y
}

func main() {
	conn, err := net.Dial("tcp", "10.0.0.4:1337")
	if err != nil {
		fmt.Printf("error\n")
	}
	b := bufio.NewReader(conn)

	var p []byte
	for {
		x, _ := b.ReadByte()
		p = append(p, x)
		if len(p) > 1000 {
			break
		}
	}
	fmt.Printf("%#v \n", p)

	// scanner := bufio.NewScanner(b)
	// scanner.Split(SplitFrames)
	//
	// for scanner.Scan() {
	//   data := scanner.Bytes()
	//
	//   // fmt.Printf("data: (%d) %X\n", len(data), data)
	//   var frame Frame
	//   if err = frame.from_bytes(data); err != nil {
	//     fmt.Printf("error: %s\n", err)
	//     continue
	//   }
	//
	//   // fmt.Printf("\ndata (%d): %+X\n", len(data), data)
	//   // fmt.Printf("frame: %+v\n", frame)
	// }
}
