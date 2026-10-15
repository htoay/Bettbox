package main

import (
	"io"
	"os"
	"path"
	"path/filepath"
	"time"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"
	"github.com/metacubex/sevenzip"
)

func bundledRuleSetTargets(rawCfg *config.RawConfig) map[string][]string {
	targets := map[string][]string{}
	for _, provider := range rawCfg.RuleProvider {
		pathInBundle, _ := provider["path-in-bundle"].(string)
		if pathInBundle == "" {
			continue
		}
		target, _ := provider["path"].(string)
		switch provider["type"] {
		case "http":
			if target == "" {
				url, _ := provider["url"].(string)
				target = constant.Path.GetPathByHash("rules", url)
			}
		case "file":
		default:
			continue
		}
		if target == "" {
			continue
		}
		target = constant.Path.Resolve(target)
		if !constant.Path.IsSafePath(target) {
			continue
		}
		if _, err := os.Stat(target); err == nil {
			continue
		}
		pathInBundle = path.Clean(filepath.ToSlash(pathInBundle))
		targets[pathInBundle] = append(targets[pathInBundle], target)
	}
	return targets
}

func writeBundledRuleSet(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	temp := path + ".bundle.tmp"
	if err := os.WriteFile(temp, data, 0o644); err != nil {
		return err
	}
	if err := os.Rename(temp, path); err != nil {
		_ = os.Remove(temp)
		return err
	}
	return nil
}

func preloadBundledRuleSets(rawCfg *config.RawConfig) {
	targets := bundledRuleSetTargets(rawCfg)
	if len(targets) == 0 {
		return
	}
	start := time.Now()
	reader, err := sevenzip.OpenReader(constant.Path.BundleMRS())
	if err != nil {
		log.Warnln("[APP] open bundle file error: %v", err)
		return
	}
	defer reader.Close()

	extracted := 0
	for _, file := range reader.File {
		paths, wanted := targets[path.Clean(filepath.ToSlash(file.Name))]
		if !wanted {
			continue
		}
		content, err := file.Open()
		if err != nil {
			log.Warnln("[APP] open %s in bundle file error: %v", file.Name, err)
			continue
		}
		data, err := io.ReadAll(content)
		_ = content.Close()
		if err != nil {
			log.Warnln("[APP] read %s in bundle file error: %v", file.Name, err)
			continue
		}
		for _, target := range paths {
			if err := writeBundledRuleSet(target, data); err != nil {
				log.Warnln("[APP] write bundled rule set %s error: %v", target, err)
				continue
			}
			extracted++
		}
	}
	log.Infoln("[APP] preload bundled rule sets: %d files in %s", extracted, time.Since(start).Round(time.Millisecond))
}
