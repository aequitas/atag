package main

import "fmt"

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

func main() {
	var in = []byte{0x10, 0x20, 0x01, 0x21, 0xf1}
	fmt.Printf("%X", Kermit(in))
}
