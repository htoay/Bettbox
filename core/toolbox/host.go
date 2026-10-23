package toolbox

import (
	"sync"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
)

const (
	MessageSpeedTest = "speedTest"
	MessageStun      = "stunTest"
	MessageIperf     = "iperf"
	MessageLocalPing = "localPing"
)

type Host struct {
	Notify  func(kind string, data any)
	State   func() (running bool, cfg *config.Config, raw *config.RawConfig)
	AgeLock sync.Locker
}

var (
	env          Host
	localAgeLock sync.Mutex
)

func Setup(h Host) {
	env = h
}

func notify(kind string, data any) {
	if env.Notify != nil {
		env.Notify(kind, data)
	}
}

func coreState() (bool, *config.Config, *config.RawConfig) {
	if env.State == nil {
		return false, nil, nil
	}
	return env.State()
}

func coreRunning() bool {
	running, _, _ := coreState()
	return running
}

func FindProxy(name string) (constant.Proxy, bool) {
	if proxy, ok := tunnel.Proxies()[name]; ok {
		return proxy, true
	}
	for _, provider := range tunnel.Providers() {
		for _, proxy := range provider.Proxies() {
			if proxy.Name() == name {
				return proxy, true
			}
		}
	}
	return nil, false
}

func ageLock() sync.Locker {
	if env.AgeLock != nil {
		return env.AgeLock
	}
	return &localAgeLock
}
