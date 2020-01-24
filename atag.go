package atag

import (
	"bytes"
	"fmt"
	"log"
)

var (
	End = []byte{0x03, 0x06}
)

func SplitFrames(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}

	end := bytes.Index(data, End)
	log.Printf("%+v\n", end)

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
