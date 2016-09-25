package test

import (
	"testing"
	"encoding/json"
	"github.com/guymers/bazel_container/container/oci/serialization"
	"github.com/opencontainers/image-spec/specs-go/v1"
)

func TestNewUser(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		User: "a_user",
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		User: "a_user",
		WorkingDir: "/home/work",
	}

	assertJsonEquals(t, expected, actual)
}

func TestOverrideUser(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			User: "z_user",
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		User: "a_user",
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		User: "a_user",
		WorkingDir: "/home/work",
	}

	assertJsonEquals(t, expected, actual)
}

func TestNewPort(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Ports: []string{"80"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		ExposedPorts: map[string]struct{}{
			"80/tcp": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestAugmentPort(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			ExposedPorts: map[string]struct{}{
				"443/tcp": struct{}{},
			},
		},
	}

	ic := serialization.ImageConfig{
		Ports: []string{"80"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		ExposedPorts: map[string]struct{}{
			"443/tcp": struct{}{},
			"80/tcp": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestMultiplePorts(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Ports: []string{"80", "8080"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		ExposedPorts: map[string]struct{}{
			"80/tcp": struct{}{},
			"8080/tcp": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestPortCollision(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			ExposedPorts: map[string]struct{}{
				"80/tcp": struct{}{},
			},
		},
	}

	ic := serialization.ImageConfig{
		Ports: []string{"80"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		ExposedPorts: map[string]struct{}{
			"80/tcp": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestPortWithProtocol(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Ports: []string{"80/udp"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		ExposedPorts: map[string]struct{}{
			"80/udp": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestEnv(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Env: []string{"foo=bar", "baz=blah"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Env: []string{"baz=blah", "foo=bar"},
	}

	assertJsonEquals(t, expected, actual)
}

func TestEnvResolveReplace(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Env: []string{
				"foo=bar",
				"baz=blah",
				"blah=still around",
				"PATH=$PATH:/custom",
			},
		},
	}

	ic := serialization.ImageConfig{
		Env: []string{
			"baz=replacement",
			"foo=$foo:asdf",
			"PATH=$PATH:/extra",
		},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Env: []string{
			"PATH=$PATH:/custom:/extra",
			"baz=replacement",
			"blah=still around",
			"foo=bar:asdf",
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestNewEntrypoint(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Entrypoint: []string{"/bin/hello"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Entrypoint: []string{"/bin/hello"},
	}

	assertJsonEquals(t, expected, actual)
}

func TestOverrideEntrypoint(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Entrypoint: []string{"/bin/sh", "does", "not", "matter"},
		},
	}

	ic := serialization.ImageConfig{
		Entrypoint: []string{"/bin/hello"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		Entrypoint: []string{"/bin/hello"},
		WorkingDir: "/home/work",
	}

	assertJsonEquals(t, expected, actual)
}

func TestNewCommand(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Command: []string{"hello"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Cmd: []string{"hello"},
	}

	assertJsonEquals(t, expected, actual)
}

func TestOverrideCommand(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Cmd: []string{"does", "not", "matter"},
		},
	}

	ic := serialization.ImageConfig{
		Command: []string{"hello"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Cmd: []string{"hello"},
	}

	assertJsonEquals(t, expected, actual)
}

func TestOverrideEntrypointAndCommand(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Entrypoint: []string{"/bin/sh"},
			Cmd: []string{"does", "not", "matter"},
		},
	}

	ic := serialization.ImageConfig{
		Entrypoint: []string{"/bin/bash"},
		Command: []string{"hello"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Entrypoint: []string{"/bin/bash"},
		Cmd: []string{"hello"},
	}

	assertJsonEquals(t, expected, actual)
}

func TestNewVolume(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Volumes: []string{"/original"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Volumes: map[string]struct{}{
			"/original": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestAugmentVolume(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Volumes: map[string]struct{}{
				"/original": struct{}{},
			},
		},
	}

	ic := serialization.ImageConfig{
		Volumes: []string{"/extra"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Volumes: map[string]struct{}{
			"/original": struct{}{},
			"/extra": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestMultipleVolumes(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		Volumes: []string{"/input", "/output"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Volumes: map[string]struct{}{
			"/input": struct{}{},
			"/output": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestAugmentVolumeWithNullInput(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			WorkingDir: "/home/work",
			Volumes: map[string]struct{}{},
		},
	}

	ic := serialization.ImageConfig{
		Volumes: []string{"/data"},
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		WorkingDir: "/home/work",
		Volumes: map[string]struct{}{
			"/data": struct{}{},
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestSetWorkingDir(t *testing.T) {
	parentImage := v1.Image{
		Config: v1.ImageConfig{
			User: "user",
			WorkingDir: "/home/work",
		},
	}

	ic := serialization.ImageConfig{
		WorkingDir: "/home/user",
	}
	actual := ic.CreateImage(parentImage).Config

	expected := v1.ImageConfig{
		User: "user",
		WorkingDir: "/home/user",
	}

	assertJsonEquals(t, expected, actual)
}

func TestLayersAddedToDiffIds(t *testing.T) {
	parentImage := v1.Image{
		RootFS: v1.RootFS{
			Type: "layers",
			DiffIDs: []string{
				"sha256:1",
				"sha256:2",
			},
		},
	}

	ic := serialization.ImageConfig{
		Layers: []string{"3", "4"},
	}
	actual := ic.CreateImage(parentImage).RootFS

	expected := v1.RootFS{
		Type: "layers",
		DiffIDs: []string{
			"sha256:1",
			"sha256:2",
			"sha256:3",
			"sha256:4",
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestHistoryAdded(t *testing.T) {
	parentImage := v1.Image{
		History: []v1.History{
			{
				Author: "Bazel",
				Created: "0001-01-01T00:00:00Z",
				CreatedBy: "bazel build ...",
			},
		},
	}

	ic := serialization.ImageConfig{
		Layers: []string{"1"},
	}
	actual := ic.CreateImage(parentImage).History

	expected := []v1.History{
		{
			Author: "Bazel",
			Created: "0001-01-01T00:00:00Z",
			CreatedBy: "bazel build ...",
		},
		{
			Author: "Bazel",
			Created: "0001-01-01T00:00:00Z",
			CreatedBy: "bazel build ...",
		},
	}

	assertJsonEquals(t, expected, actual)
}

func TestHistoryAddedEmptyLayer(t *testing.T) {
	parentImage := v1.Image{
		History: []v1.History{
			{
				Author: "Bazel",
				Created: "0001-01-01T00:00:00Z",
				CreatedBy: "bazel build ...",
			},
		},
	}

	ic := serialization.ImageConfig{
		Layers: []string{},
	}
	actual := ic.CreateImage(parentImage).History

	expected := []v1.History{
		{
			Author: "Bazel",
			Created: "0001-01-01T00:00:00Z",
			CreatedBy: "bazel build ...",
		},
		{
			Author: "Bazel",
			Created: "0001-01-01T00:00:00Z",
			CreatedBy: "bazel build ...",
			EmptyLayer: true,
		},
	}

	assertJsonEquals(t, expected, actual)
}

func assertJsonEquals(t *testing.T, expected interface{}, actual interface{}) {
	if ! jsonEquals(expected, actual) {
		expectedJson, _ := json.Marshal(expected)
		t.Log(string(expectedJson))
		actualJson, _ := json.Marshal(actual)
		t.Log(string(actualJson))
		t.Fail()
	}
}

func jsonEquals(x interface{}, y interface{}) bool {
	// converting something to string should never fail...
	xJson, _ := json.Marshal(x)
	yJson, _ := json.Marshal(y)
	return string(xJson) == string(yJson)
}
