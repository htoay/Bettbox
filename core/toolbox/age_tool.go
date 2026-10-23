package toolbox

import (
	"encoding/json"
	"errors"
	"strings"

	"github.com/metacubex/mihomo/component/age"
)

var errAgeNotEncrypted = errors.New("not age encrypted")

type AgeCryptParams struct {
	Mode string   `json:"mode"`
	Data string   `json:"data"`
	Keys []string `json:"keys"`
}

type AgeCryptResult struct {
	Data  string `json:"data"`
	Error string `json:"error"`
}

func HandleAgeCrypt(paramsString string) string {
	params := AgeCryptParams{}
	_ = json.Unmarshal([]byte(paramsString), &params)
	keys := make([]string, 0, len(params.Keys))
	for _, key := range params.Keys {
		if key = strings.TrimSpace(key); key != "" {
			keys = append(keys, key)
		}
	}
	result := AgeCryptResult{}
	var (
		data []byte
		err  error
	)
	if params.Mode == "encrypt" {
		data, err = age.EncryptBytes([]byte(params.Data), keys...)
	} else if !strings.HasPrefix(strings.TrimSpace(params.Data), age.FileHeader) {
		err = errAgeNotEncrypted
	} else {
		ageLock().Lock()
		data, err = age.DecryptBytes([]byte(strings.TrimSpace(params.Data)), keys...)
		ageLock().Unlock()
	}
	if err != nil {
		result.Error = err.Error()
	} else {
		result.Data = string(data)
	}
	encoded, _ := json.Marshal(result)
	if len(params.Data) > 1<<20 {
		releaseToolMemory()
	}
	return string(encoded)
}
