package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/config"
)

func runtimeConfigFor(t *testing.T, name, content string, patch *PatchParams) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	params := &SetupParams{ProfilePath: path, Patch: patch}
	if strings.HasSuffix(name, ".json") {
		params = &SetupParams{ScriptedConfig: path, Patch: patch}
	}
	out, err := handleGetRuntimeConfig(params)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := config.UnmarshalRawConfig([]byte(out)); err != nil {
		t.Fatalf("output is not a valid config: %v\n%s", err, out)
	}
	return out
}

func TestRuntimeConfigKeepsProfileShape(t *testing.T) {
	profile := `# comment
mixed-port: 7890
proxies:
  - {name: "🇭🇰 HK", type: ss, server: a.com, port: 1, cipher: aes-128-gcm, password: x}
proxy-groups:
  - name: G
    type: select
    proxies: ["🇭🇰 HK"]
rules:
  - MATCH,G
`
	out := runtimeConfigFor(t, "p.yaml", profile, nil)
	want := `mixed-port: 7890
proxies:
  - name: 🇭🇰 HK
    type: ss
    server: a.com
    port: 1
    cipher: aes-128-gcm
    password: x
proxy-groups:
  - name: G
    type: select
    proxies:
      - 🇭🇰 HK
rules:
  - MATCH,G
`
	if out != want {
		t.Fatalf("got:\n%s\nwant:\n%s", out, want)
	}
}

func TestRuntimeConfigAppendsPatchedFields(t *testing.T) {
	profile := `proxies:
  - name: A
    type: ss
    server: a.com
    port: 1
    cipher: aes-128-gcm
    password: x
mode: global
rules:
  - MATCH,DIRECT
`
	patch := &PatchParams{
		General:            []byte(`{"mode":"rule","mixed-port":7891,"log-level":"info"}`),
		HealthCheckTimeout: defaultHealthCheckTimeout,
		PrependRules:       []string{"DOMAIN,a.com,DIRECT"},
	}
	out := runtimeConfigFor(t, "p.yaml", profile, patch)
	if !strings.HasPrefix(out, "proxies:\n  - name: A\n    type: ss\n") {
		t.Fatalf("profile order changed:\n%s", out)
	}
	if !strings.Contains(out, "\nmode: rule\nrules:\n  - DOMAIN,a.com,DIRECT\n  - MATCH,DIRECT\n") {
		t.Fatalf("patched fields not in place:\n%s", out)
	}
	for _, line := range []string{"\nmixed-port: 7891\n", "\nlog-level: info\n"} {
		if !strings.Contains(out, line) {
			t.Fatalf("forced field %q missing:\n%s", line, out)
		}
	}
	for _, line := range []string{"tuic-server:", "iptables:", "ss-config:", "socks-port:"} {
		if strings.Contains(out, line) {
			t.Fatalf("untouched default %q leaked:\n%s", line, out)
		}
	}
}

func TestRuntimeConfigExpandsAliases(t *testing.T) {
	profile := `base: &base
  type: select
  proxies: [DIRECT]
proxy-groups:
  - name: G
    <<: *base
  - name: H
    <<: *base
    type: fallback
rules:
  - MATCH,G
`
	out := runtimeConfigFor(t, "p.yaml", profile, nil)
	if strings.Contains(out, "*base") || strings.Contains(out, "&base") || strings.Contains(out, "<<") {
		t.Fatalf("aliases kept:\n%s", out)
	}
	if !strings.Contains(out, "  - name: H\n    proxies:\n      - DIRECT\n    type: fallback\n") {
		t.Fatalf("merge key not expanded:\n%s", out)
	}
}

func TestRuntimeConfigScriptedUsesBlockStyle(t *testing.T) {
	scripted := `{"mixed-port":7890,"proxies":[{"name":"A","type":"ss","server":"a.com","port":1,"cipher":"aes-128-gcm","password":"0123"}],"rules":["MATCH,DIRECT"]}`
	out := runtimeConfigFor(t, "s.json", scripted, nil)
	want := `mixed-port: 7890
proxies:
  - name: A
    type: ss
    server: a.com
    port: 1
    cipher: aes-128-gcm
    password: "0123"
rules:
  - MATCH,DIRECT
`
	if out != want {
		t.Fatalf("got:\n%s\nwant:\n%s", out, want)
	}
}
