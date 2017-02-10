package serialization

import (
	"github.com/spf13/cobra"
)

var RootCmd = &cobra.Command{
	Use: "image-config",
}

type ImageConfigCommand struct {
	Base       string
	Output     string
	Layers     []string

	User       string
	Ports      []string
	Env        []string
	Entrypoint []string
	Command    []string
	Volumes    []string
	WorkingDir string
	Labels     []string
}

var cmdConfig ImageConfigCommand

func init() {
	RootCmd.Flags().StringVar(&cmdConfig.Base, "base", "", "Path to the parent images config")
	RootCmd.Flags().StringVar(&cmdConfig.Output, "output", "", "The output file to generate")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Layers, "layer", []string{}, "Layer sha256 hashes that make up this image")

	RootCmd.Flags().StringVar(&cmdConfig.User, "user", "", "Set the 'User' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Ports, "port", []string{}, "Augment the 'ExposedPorts' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Env, "env", []string{}, "Augment the 'Env' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Entrypoint, "entry-point", []string{}, "Set the 'Entrypoint' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Command, "command", []string{}, "Set the 'Cmd' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Volumes, "volume", []string{}, "Augment the 'Volumes' for the image")
	RootCmd.Flags().StringVar(&cmdConfig.WorkingDir, "working-dir", "", "Set the 'WorkingDir' for the image")
	RootCmd.Flags().StringSliceVar(&cmdConfig.Labels, "label", []string{}, "Augment the 'Labels' for the image")
}

func Execute() (ImageConfigCommand, error) {
	err := RootCmd.Execute()
	if err != nil {
		return cmdConfig, err
	}

	return cmdConfig, nil
}
