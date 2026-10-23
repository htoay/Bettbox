package toolbox

import (
	"context"
	"encoding/json"
	"strconv"
	"strings"
	"time"

	"github.com/metacubex/mihomo/component/resolver"
	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
	D "github.com/miekg/dns"
)

const (
	dnsQueryModeFollow = "follow"
	dnsQueryModeSystem = "system"
	dnsQueryModeCustom = "custom"

	dnsQueryErrorStopped = "stopped"
	dnsQueryErrorInvalid = "invalid"
	dnsQueryErrorServer  = "server"

	dnsRouteHosts   = "hosts"
	dnsRouteFakeIP  = "fake-ip"
	dnsRouteRealIP  = "real-ip"
	dnsRouteMapping = "mapping"
	dnsRouteNormal  = "normal"
)

type DnsQueryParams struct {
	Domain string `json:"domain"`
	Type   string `json:"type"`
	Mode   string `json:"mode"`
	Server string `json:"server"`
}

type DnsQueryRecord struct {
	Name string `json:"name"`
	Type string `json:"type"`
	TTL  uint32 `json:"ttl"`
	Data string `json:"data"`
}

type DnsQueryResult struct {
	Domain       string           `json:"domain"`
	Type         string           `json:"type"`
	Mode         string           `json:"mode"`
	Server       string           `json:"server"`
	Rcode        string           `json:"rcode"`
	Answers      []DnsQueryRecord `json:"answers"`
	Elapsed      float64          `json:"elapsed"`
	Route        string           `json:"route"`
	Hosts        []string         `json:"hosts"`
	FakeIPRange  string           `json:"fake-ip-range"`
	FilterMode   string           `json:"filter-mode"`
	Outbound     string           `json:"outbound"`
	OutboundType string           `json:"outbound-type"`
	Error        string           `json:"error"`
}

func dnsQueryOutbound(ctx context.Context, domain string) (string, string) {
	trace := runRouteTrace(ctx, RouteTraceParams{Target: domain, Network: "tcp", Port: 443})
	if len(trace.Chains) == 0 {
		return "", ""
	}
	first := trace.Chains[0]
	last := trace.Chains[len(trace.Chains)-1]
	name := first.Name
	if last.Name != first.Name {
		name += " → " + last.Name
	}
	return name, last.Type
}

func dnsQueryRoute(cfg *config.DNS, domain string) (string, []string) {
	if cfg == nil || !cfg.Enable {
		return "", nil
	}
	if cfg.UseHosts {
		if record, ok := resolver.DefaultHosts.Search(domain, false); ok && record != nil && !record.IsDomain {
			ips := make([]string, 0, len(record.IPs))
			for _, ip := range record.IPs {
				ips = append(ips, ip.String())
			}
			return dnsRouteHosts, ips
		}
	}
	switch cfg.EnhancedMode {
	case C.DNSFakeIP:
		if cfg.FakeIPSkipper != nil && cfg.FakeIPSkipper.ShouldSkipped(domain) {
			return dnsRouteRealIP, nil
		}
		return dnsRouteFakeIP, nil
	case C.DNSMapping:
		return dnsRouteMapping, nil
	}
	return dnsRouteNormal, nil
}

func dnsQueryType(value string) uint16 {
	if kind, ok := D.StringToType[strings.ToUpper(value)]; ok {
		return kind
	}
	return D.TypeA
}

func dnsRecordData(rr D.RR) string {
	switch record := rr.(type) {
	case *D.A:
		return record.A.String()
	case *D.AAAA:
		return record.AAAA.String()
	case *D.CNAME:
		return record.Target
	case *D.NS:
		return record.Ns
	case *D.PTR:
		return record.Ptr
	case *D.MX:
		return record.Mx + " (" + strconv.Itoa(int(record.Preference)) + ")"
	case *D.TXT:
		return strings.Join(record.Txt, " ")
	}
	header := rr.Header().String()
	return strings.TrimSpace(strings.TrimPrefix(rr.String(), header))
}

func runDnsQuery(ctx context.Context, params DnsQueryParams, running bool, cfg *config.DNS) DnsQueryResult {
	domain := strings.TrimSuffix(strings.ToLower(strings.TrimSpace(params.Domain)), ".")
	kind := dnsQueryType(params.Type)
	result := DnsQueryResult{
		Domain:  domain,
		Type:    D.TypeToString[kind],
		Mode:    params.Mode,
		Answers: []DnsQueryRecord{},
	}
	if host, _, ok := parseRouteTarget(domain); ok && host != "" {
		domain = host
		result.Domain = host
	} else {
		result.Error = dnsQueryErrorInvalid
		return result
	}

	var query interface {
		ExchangeContext(ctx context.Context, m *D.Msg) (*D.Msg, error)
	}
	switch params.Mode {
	case dnsQueryModeCustom:
		servers, err := dns.ParseNameServer([]string{strings.TrimSpace(params.Server)})
		if err != nil || len(servers) == 0 {
			result.Error = dnsQueryErrorServer
			return result
		}
		result.Server = params.Server
		resolvers := dns.NewResolver(dns.Config{
			Main:    servers,
			Default: []dns.NameServer{{Net: "system"}},
		})
		defer resolvers.ResetConnection()
		query = resolvers.Resolver
	case dnsQueryModeSystem:
		result.Server = "system"
		resolvers := dns.NewResolver(dns.Config{
			Main:    []dns.NameServer{{Net: "system"}},
			Default: []dns.NameServer{{Net: "system"}},
		})
		defer resolvers.ResetConnection()
		query = resolvers.Resolver
	default:
		result.Mode = dnsQueryModeFollow
		if !running || resolver.DefaultResolver == nil {
			result.Error = dnsQueryErrorStopped
			return result
		}
		query = resolver.DefaultResolver
		result.Route, result.Hosts = dnsQueryRoute(cfg, domain)
		if result.Route == dnsRouteFakeIP && cfg.FakeIPRange.IsValid() {
			result.FakeIPRange = cfg.FakeIPRange.String()
		}
		if (result.Route == dnsRouteFakeIP || result.Route == dnsRouteRealIP) && cfg.FakeIPSkipper != nil {
			result.FilterMode = cfg.FakeIPSkipper.Mode.String()
		}
		if result.Route != "" && result.Route != dnsRouteNormal {
			result.Outbound, result.OutboundType = dnsQueryOutbound(ctx, domain)
		}
	}

	msg := &D.Msg{}
	msg.SetQuestion(D.Fqdn(domain), kind)
	msg.RecursionDesired = true
	queryCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	start := time.Now()
	reply, err := query.ExchangeContext(queryCtx, msg)
	result.Elapsed = float64(time.Since(start).Microseconds()) / 1000
	if err != nil {
		result.Error = err.Error()
		return result
	}
	result.Rcode = D.RcodeToString[reply.Rcode]
	for _, rr := range reply.Answer {
		header := rr.Header()
		result.Answers = append(result.Answers, DnsQueryRecord{
			Name: strings.TrimSuffix(header.Name, "."),
			Type: D.TypeToString[header.Rrtype],
			TTL:  header.Ttl,
			Data: strings.TrimSuffix(dnsRecordData(rr), "."),
		})
	}
	return result
}

func HandleDnsQuery(paramsString string) string {
	params := DnsQueryParams{}
	_ = json.Unmarshal([]byte(paramsString), &params)
	running, current, _ := coreState()
	var cfg *config.DNS
	if current != nil {
		cfg = current.DNS
	}
	result := runDnsQuery(context.Background(), params, running, cfg)
	data, _ := json.Marshal(result)
	return string(data)
}
