package toolbox

import (
	"context"
	"encoding/json"
	"net/netip"
	"strings"
	"time"

	"github.com/metacubex/mihomo/component/resolver"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
)

const (
	routeTraceMaxSteps = 3000

	routeTraceErrorStopped = "stopped"
	routeTraceErrorInvalid = "invalid"
)

type RouteTraceParams struct {
	Target  string `json:"target"`
	Network string `json:"network"`
	Port    int    `json:"port"`
}

type RouteTraceStep struct {
	Index    int    `json:"index"`
	Type     string `json:"type"`
	Payload  string `json:"payload"`
	Adapter  string `json:"adapter"`
	Matched  bool   `json:"matched"`
	Resolve  bool   `json:"resolve"`
	Skipped  string `json:"skipped,omitempty"`
	Duration int64  `json:"duration"`
}

type RouteTraceChain struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

type RouteTraceResult struct {
	Target         string            `json:"target"`
	Host           string            `json:"host"`
	Network        string            `json:"network"`
	Port           int               `json:"port"`
	Mode           string            `json:"mode"`
	DnsMode        string            `json:"dns-mode"`
	HostsIPs       []string          `json:"hosts-ips"`
	ResolvedIPs    []string          `json:"resolved-ips"`
	ResolveTime    float64           `json:"resolve-time"`
	ResolveError   string            `json:"resolve-error"`
	ResolvedBy     int               `json:"resolved-by"`
	DstIP          string            `json:"dst-ip"`
	Total          int               `json:"total"`
	Checked        int               `json:"checked"`
	Truncated      bool              `json:"truncated"`
	Steps          []RouteTraceStep  `json:"steps"`
	Matched        *RouteTraceStep   `json:"matched,omitempty"`
	Chains         []RouteTraceChain `json:"chains"`
	SupportUDP     bool              `json:"support-udp"`
	MatchTime      float64           `json:"match-time"`
	Error          string            `json:"error"`
	FallbackDirect bool              `json:"fallback-direct"`
}

func parseRouteTarget(target string) (host string, ip netip.Addr, ok bool) {
	target = strings.TrimSpace(target)
	if index := strings.Index(target, "://"); index >= 0 {
		target = target[index+3:]
	}
	if index := strings.IndexAny(target, "/?#"); index >= 0 {
		target = target[:index]
	}
	if strings.HasPrefix(target, "[") {
		if end := strings.Index(target, "]"); end > 0 {
			target = target[1:end]
		}
	} else if strings.Count(target, ":") == 1 {
		target = target[:strings.Index(target, ":")]
	}
	target = strings.TrimSuffix(strings.ToLower(target), ".")
	if target == "" {
		return "", netip.Addr{}, false
	}
	if addr, err := netip.ParseAddr(target); err == nil {
		return "", addr.Unmap(), true
	}
	if strings.ContainsAny(target, " \t") {
		return "", netip.Addr{}, false
	}
	return target, netip.Addr{}, true
}

func traceChains(proxy constant.Proxy, metadata *constant.Metadata) ([]RouteTraceChain, bool) {
	chains := []RouteTraceChain{}
	supportUDP := true
	for current := proxy; current != nil; current = current.Unwrap(metadata, false) {
		chains = append(chains, RouteTraceChain{Name: current.Name(), Type: current.Type().String()})
		supportUDP = current.SupportUDP()
		if len(chains) > 16 {
			break
		}
	}
	return chains, supportUDP
}

func runRouteTrace(ctx context.Context, params RouteTraceParams) RouteTraceResult {
	result := RouteTraceResult{
		Target:     params.Target,
		Network:    strings.ToLower(params.Network),
		Port:       params.Port,
		Mode:       tunnel.Mode().String(),
		ResolvedBy: -1,
		Steps:      []RouteTraceStep{},
		Chains:     []RouteTraceChain{},
	}
	if result.Network != "udp" {
		result.Network = "tcp"
	}
	if result.Port <= 0 || result.Port > 65535 {
		result.Port = 443
	}
	host, ip, ok := parseRouteTarget(params.Target)
	if !ok {
		result.Error = routeTraceErrorInvalid
		return result
	}
	result.Host = host
	if _, _, raw := coreState(); raw != nil && raw.DNS.Enable {
		result.DnsMode = raw.DNS.EnhancedMode.String()
	}

	metadata := &constant.Metadata{
		NetWork: constant.TCP,
		Type:    constant.INNER,
		DNSMode: constant.DNSNormal,
		Process: constant.MihomoName,
		InName:  "RouteTrace",
		Host:    host,
		DstIP:   ip,
		DstPort: uint16(result.Port),
	}
	if result.Network == "udp" {
		metadata.NetWork = constant.UDP
	}

	resolved := ip.IsValid()
	if host != "" {
		if node, ok := resolver.DefaultHosts.Search(host, false); ok {
			for _, addr := range node.IPs {
				result.HostsIPs = append(result.HostsIPs, addr.String())
			}
			if addr, err := node.RandIP(); err == nil {
				metadata.DstIP = addr
				resolved = true
			}
		}
	}

	current := -1
	helper := constant.RuleMatchHelper{
		ResolveIP: func() {
			if resolved || host == "" {
				return
			}
			resolved = true
			result.ResolvedBy = current
			resolveCtx, cancel := context.WithTimeout(ctx, resolver.DefaultDNSTimeout)
			defer cancel()
			start := time.Now()
			ips, err := resolver.LookupIP(resolveCtx, host)
			result.ResolveTime = float64(time.Since(start).Microseconds()) / 1000
			if err != nil {
				result.ResolveError = err.Error()
				return
			}
			for _, addr := range ips {
				result.ResolvedIPs = append(result.ResolvedIPs, addr.String())
			}
			if len(ips) > 0 {
				metadata.DstIP = ips[0]
			}
		},
		FindProcess: func() {},
	}

	var proxy constant.Proxy
	start := time.Now()
	switch tunnel.Mode() {
	case tunnel.Direct:
		proxy, _ = FindProxy("DIRECT")
	case tunnel.Global:
		proxy, _ = FindProxy("GLOBAL")
	default:
		rules := tunnel.Rules()
		result.Total = len(rules)
	rules:
		for index, rule := range rules {
			if ctx.Err() != nil {
				result.Error = stunErrorCancelled
				return result
			}
			current = index
			ruleStart := time.Now()
			matched, adapterName := rule.Match(metadata, helper)
			step := RouteTraceStep{
				Index:    index,
				Type:     rule.RuleType().String(),
				Payload:  rule.Payload(),
				Adapter:  rule.Adapter(),
				Resolve:  result.ResolvedBy == index,
				Duration: time.Since(ruleStart).Microseconds(),
			}
			result.Checked++
			if matched {
				step.Adapter = adapterName
				adapter, ok := FindProxy(adapterName)
				switch {
				case !ok:
					step.Skipped = "missing"
				case metadata.NetWork == constant.UDP && !adapter.SupportUDP():
					step.Skipped = "udp"
				default:
					for unwrap := adapter; unwrap != nil; unwrap = unwrap.Unwrap(metadata, false) {
						if unwrap.Type() == constant.Pass {
							step.Skipped = "pass"
							break
						}
					}
				}
				if step.Skipped == "" {
					step.Matched = true
					proxy = adapter
				}
			}
			if len(result.Steps) < routeTraceMaxSteps {
				result.Steps = append(result.Steps, step)
			} else {
				result.Truncated = true
			}
			if step.Matched {
				matchedStep := step
				result.Matched = &matchedStep
				break rules
			}
		}
		if proxy == nil {
			proxy, _ = FindProxy("DIRECT")
			result.FallbackDirect = true
		}
	}
	result.MatchTime = float64(time.Since(start).Microseconds()) / 1000
	if metadata.DstIP.IsValid() {
		result.DstIP = metadata.DstIP.String()
	}
	if proxy != nil {
		result.Chains, result.SupportUDP = traceChains(proxy, metadata)
	}
	return result
}

func HandleRouteTrace(paramsString string) string {
	params := RouteTraceParams{}
	_ = json.Unmarshal([]byte(paramsString), &params)
	running := coreRunning()
	var result RouteTraceResult
	if !running {
		result = RouteTraceResult{Target: params.Target, Error: routeTraceErrorStopped, Steps: []RouteTraceStep{}, Chains: []RouteTraceChain{}}
	} else {
		ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		result = runRouteTrace(ctx, params)
		cancel()
	}
	data, _ := json.Marshal(result)
	return string(data)
}
