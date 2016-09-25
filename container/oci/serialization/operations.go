package serialization

import (
	"errors"
	"fmt"
	"encoding/json"
	"io/ioutil"
	"github.com/opencontainers/image-spec/specs-go/v1"
)

func CreateDefaultImage(baseImageConfigFile string) (v1.Image, error) {
	var image v1.Image

	if baseImageConfigFile != "" {
		file, e := ioutil.ReadFile(baseImageConfigFile)
		if e != nil {
			errStr := fmt.Sprintf("Could not read base file: %v\n", e)
			return image, errors.New(errStr)
		}

		err := json.Unmarshal(file, &image)
		if err != nil {
			errStr := fmt.Sprintf("Could not convert base file to image config: %v\n", err)
			return image, errors.New(errStr)
		}
	}

	return image, nil
}

func SaveImageToFile(image v1.Image, filename string) error {
	if filename == "" {
		return errors.New("No output filename provided")
	}

	imageJson, err := json.Marshal(image)
	if err != nil {
		errStr := fmt.Sprintf("Could not convert to json: %v\n", err)
		return errors.New(errStr)
	}

	err = ioutil.WriteFile(filename, imageJson, 0644)
	if err != nil {
		errStr := fmt.Sprintf("Could not write to file '%s': %v\n", filename, err)
		return errors.New(errStr)
	}

	return nil
}
