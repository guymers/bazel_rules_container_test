package serialization

import (
	"os"
	"sort"
	"strings"
	"github.com/opencontainers/image-spec/specs-go/v1"
)

type ImageConfig struct {
	Layers     []string

	User       string
	Memory     int64
	MemorySwap int64
	CPUShares  int64
	Ports      []string
	Env        []string
	Entrypoint []string
	Command    []string
	Volumes    []string
	WorkingDir string
}

func (ic *ImageConfig) CreateImage(parentImage v1.Image) v1.Image {
	return v1.Image{
		Created: "0001-01-01T00:00:00Z",
		Author: "Bazel",
		Architecture: "amd64",
		OS: "linux",
		Config: ic.imageConfig(parentImage.Config),
		RootFS: ic.imageRootFS(parentImage.RootFS),
		History: ic.imageHistory(parentImage.History),
	}
}

func (ic *ImageConfig) imageConfig(imageConfig v1.ImageConfig) v1.ImageConfig {
	if ic.User != "" {
		imageConfig.User = ic.User
	}

	if ic.Memory != 0 {
		imageConfig.Memory = ic.Memory
	}

	if ic.MemorySwap != 0 {
		imageConfig.MemorySwap = ic.MemorySwap
	}

	if ic.CPUShares != 0 {
		imageConfig.CPUShares = ic.CPUShares
	}

	for _, port := range ic.Ports {
		// The port spec has the form 80/tcp, 1234/udp so we simply use it as the key.
		if ! strings.Contains(port, "/") {
			// Assume tcp
			port = port + "/tcp"
		}

		if imageConfig.ExposedPorts == nil {
			imageConfig.ExposedPorts = make(map[string]struct{})
		}
		imageConfig.ExposedPorts[port] = struct{}{}
	}

	if len(ic.Env) > 0 {
		env := arrayToMap(imageConfig.Env, "=")
		newEnv := make(map[string]string)
		for k, v := range env {
			newEnv[k] = v
		}
		for k, v := range arrayToMap(ic.Env, "=") {
			newEnv[k] = os.Expand(v, mapGet(env))
		}
		envArray := make([]string, 0)
		for k, v := range newEnv {
			envArray = append(envArray, k + "=" + v)
		}
		sort.Strings(envArray)
		imageConfig.Env = envArray
	}

	if len(ic.Entrypoint) > 0 {
		imageConfig.Entrypoint = ic.Entrypoint
	}

	if len(ic.Command) > 0 {
		imageConfig.Cmd = ic.Command
	}

	for _, volume := range ic.Volumes {
		if imageConfig.Volumes == nil {
			imageConfig.Volumes = make(map[string]struct{})
		}
		imageConfig.Volumes[volume] = struct{}{}
	}

	if ic.WorkingDir != "" {
		imageConfig.WorkingDir = ic.WorkingDir
	}

	return imageConfig
}

func arrayToMap(arr []string, sep string) map[string]string {
	m := make(map[string]string)
	for _, str := range arr {
		s := strings.Split(str, sep)
		var key = str
		var value = ""
		if len(s) > 0 {
			key = s[0]
			value = ""
			if len(s) > 1 {
				t := s[1:]
				value = strings.Join(t, sep)
			}
		}
		m[key] = value
	}
	return m
}

func mapGet(m map[string]string) func(string) string {
	return func(k string) string {
		if val, ok := m[k]; ok {
			return val
		}
		return k
	}
}

func (ic *ImageConfig) imageRootFS(rootFS v1.RootFS) v1.RootFS {
	rootFS.Type = "layers"

	// diff_ids are ordered from bottom-most to top-most
	diffIds := rootFS.DiffIDs
	for _, l := range ic.Layers {
		diffIds = append(diffIds, "sha256:" + l)
	}
	rootFS.DiffIDs = diffIds

	return rootFS
}

func (ic *ImageConfig) imageHistory(history []v1.History) []v1.History {
	// docker only allows the child to have one more history entry than the parent
	historyEntry := v1.History{
		Created: "0001-01-01T00:00:00Z",
		CreatedBy: "bazel build ...",
		Author: "Bazel",
	}
	if len(ic.Layers) == 0 {
		historyEntry.EmptyLayer = true
	}

	// history is ordered from bottom-most layer to top-most layer
	return append(history, historyEntry)
}
