//go:build (android || ohos) && cgo

package platform

import "syscall"

var nullFd int
var maxFdCount int

func init() {
	fd, err := syscall.Open("/dev/null", syscall.O_WRONLY, 0644)
	if err != nil {
		panic(err.Error())
	}

	nullFd = fd

	var limit syscall.Rlimit

	if err := syscall.Getrlimit(syscall.RLIMIT_NOFILE, &limit); err != nil {
		maxFdCount = 1024
	} else {
		// RLIM_INFINITY 在不同 libc/内核下可能表现为 -1 或极大值：
		// 直接参与 int 运算会得到 0（甚至负值），ShouldBlockConnection 会
		// 对每个 socket 返回 true，导致所有出站连接被"屏蔽"。
		if limit.Cur <= 0 || limit.Cur > 1<<20 {
			maxFdCount = 1024
		} else {
			maxFdCount = int(limit.Cur)
		}
	}

	maxFdCount = maxFdCount / 4 * 3
}

func ShouldBlockConnection() bool {
	fd, err := syscall.Dup(nullFd)
	if err != nil {
		return true
	}

	_ = syscall.Close(fd)

	if fd > maxFdCount {
		return true
	}

	return false
}
