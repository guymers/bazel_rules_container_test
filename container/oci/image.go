package main

import (
	"errors"
	"fmt"
	"github.com/guymers/bazel_container/container/oci/serialization"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	err := run()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func run() error {
	cmdConfig, err := serialization.Execute()
	if err != nil {
		return err
	}

	parentImage, err := serialization.CreateDefaultImage(cmdConfig.Base)
	if err != nil {
		return err
	}

	layers := []string{}
	for _, l := range cmdConfig.Layers {
		if strings.HasPrefix(l, "@") {
			layerFilename := l[1:]
			layerId, e := ioutil.ReadFile(layerFilename)
			if err != nil {
				errStr := fmt.Sprintf("Could not read layer file: %v\n", e)
				return errors.New(errStr)
			}
			layers = append(layers, string(layerId))
		} else {
			layers = append(layers, l)
		}
	}

	ic := serialization.ImageConfig{
		Layers: layers,

		User:       cmdConfig.User,
		Ports:      cmdConfig.Ports,
		Env:        cmdConfig.Env,
		Entrypoint: cmdConfig.Entrypoint,
		Command:    cmdConfig.Command,
		Volumes:    cmdConfig.Volumes,
		WorkingDir: cmdConfig.WorkingDir,
		Labels:     cmdConfig.Labels,
	}
	image := ic.CreateImage(parentImage)
	errr := serialization.SaveImageToFile(image, cmdConfig.Output)
	if errr != nil {
		return errr
	}

	return nil
}
