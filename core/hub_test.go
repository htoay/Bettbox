package main

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/common/yaml"
	"github.com/metacubex/mihomo/log"
)

func TestPatchYamlShortID(t *testing.T) {
	cases := map[string]string{
		"    short-id: 0123abcd\n":                    "    short-id: \"0123abcd\"\n",
		"    short-id: 1e5\n":                         "    short-id: \"1e5\"\n",
		"    short-id: 12345678 # note\n":             "    short-id: \"12345678\" # note\n",
		"    short-id:   ABCDEF\n":                    "    short-id:   \"ABCDEF\"\n",
		"reality-opts: {public-key: k, short-id: 01}": "reality-opts: {public-key: k, short-id: \"01\"}",
		"{short-id: 01, public-key: k}":               "{short-id: \"01\", public-key: k}",
		"    short-id: \"0123abcd\"\n":                "    short-id: \"0123abcd\"\n",
		"    short-id: '0123abcd'\n":                  "    short-id: '0123abcd'\n",
		"    short-id: xyz\n":                         "    short-id: xyz\n",
		"    short-id: 0123abcdxyz\n":                 "    short-id: 0123abcdxyz\n",
		"    short-id:\n":                             "    short-id:\n",
		"    short-id: 0123abcd":                      "    short-id: \"0123abcd\"",
	}
	for input, want := range cases {
		if got := string(patchYamlShortID([]byte(input))); got != want {
			t.Errorf("patchYamlShortID(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestLogHistoryCarriesTime(t *testing.T) {
	handleClearLogs()
	t.Cleanup(func() { handleClearLogs() })
	recordLogHistory(logEntry{
		Event: log.Event{LogLevel: log.WARNING, Payload: "[DNS] timeout"},
		Time:  1760000000123,
	})
	var items []map[string]any
	if err := json.Unmarshal([]byte(handleGetLogs()), &items); err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 {
		t.Fatalf("len = %d, want 1", len(items))
	}
	want := map[string]any{
		"LogLevel": "warning",
		"Payload":  "[DNS] timeout",
		"time":     float64(1760000000123),
	}
	if !reflect.DeepEqual(items[0], want) {
		t.Errorf("entry = %v, want %v", items[0], want)
	}
}

func TestMarshalYamlKeepingSupplementary(t *testing.T) {
	type entry struct {
		Name  string `yaml:"name"`
		Value string `yaml:"value"`
	}
	entries := []entry{
		{"🇭🇰 香港 01 ⭐", "0123"},
		{"🚀 节点选择", "true"},
		{`literal \U0001F680 text`, "line one\nline two 🚀\n"},
		{"☁️ plain \ue000", "quoted \"🚀\" \\U0001F680"},
	}
	out, err := marshalYamlKeepingSupplementary(map[string]any{"entries": entries})
	if err != nil {
		t.Fatal(err)
	}
	content := string(out)
	for _, shown := range []string{"🇭🇰 香港 01 ⭐", "🚀 节点选择", "line two 🚀"} {
		if !strings.Contains(content, shown) {
			t.Fatalf("%q is escaped in: %s", shown, content)
		}
	}
	var parsed map[string][]entry
	if err := yaml.Unmarshal(out, &parsed); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(parsed["entries"], entries) {
		t.Fatalf("entries changed: %#v", parsed["entries"])
	}
}
