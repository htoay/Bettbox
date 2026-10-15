//go:build ohos && cgo

package main

// #include <time.h>
import "C"
import "time"

func init() {
	var currentT C.time_t
	var currentTM C.struct_tm
	C.time(&currentT)
	C.localtime_r(&currentT, &currentTM)
	tzOffset := int(currentTM.tm_gmtoff)
	tz := C.GoString(currentTM.tm_zone)
	time.Local = time.FixedZone(tz, tzOffset)
}
