// z13ctl — Hardware control CLI for ASUS ROG Flow Z13 (GZ302EA)
// Usage: z13ctl [command]

package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"encoding/json"
	"strings"
)

var version string

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	cmd := os.Args[1]
	switch cmd {
	case "version", "-v", "--version":
		fmt.Println("z13ctl v" + version)
	case "help", "-h", "--help":
		printUsage()
	default:
		runCommand(cmd, os.Args[2:])
	}
}

func printUsage() {
	fmt.Println(`z13ctl — Hardware control CLI for ASUS ROG Flow Z13 (GZ302EA)

USAGE:
  z13ctl [command] [options]

COMMANDS:
  status     Show current hardware state
  rgb        Control keyboard RGB lighting
  fan        Configure fan curves and speed targets  
  battery    Set battery charge limit
  sound      Enable/disable boot chime
  overdrive  Toggle panel overdrive (refresh rate boost)

RGB COMMANDS:
  z13ctl rgb on|off         Toggle power
  z13ctl rgb mode <id>      Select light pattern by ID (0-7)
  z13ctl rgb speed <0-255>  Set brightness level
  z13ctl rgb zone <n>       Control specific zone (1-6)

FAN COMMANDS:
  z13ctl fan status         Show current speeds and targets
  z13ctl fan set            Apply performance preset
  z13ctl fan balance       Balance all fans to match target

BATTERY COMMANDS:
  z13ctl battery status     Show charge limit settings
  z13ctl battery set <0-100> Set charge limit percentage

EXAMPLES:
  z13ctl rgb on
  z13ctl fan status
  z13ctl battery set 80
`)
}

func runCommand(cmd string, args []string) {
	switch cmd {
	case "status":
		showStatus()
	case "rgb", "fan", "battery", "sound", "overdrive":
		runZ13ctlCmd(args)
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\nUse 'z13ctl help' for usage.\n", cmd)
		os.Exit(2)
	}
}

func showStatus() {
	runZ13ctlCmd([]string{"-json"})
}

func runZ13ctlCmd(args []string) {
	cmd := exec.CommandContext(context.Background(), "/usr/bin/z13ctl", args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to execute z13ctl: %v\n", err)
		os.Exit(1)
	}

	var data struct {
		Power        bool `json:"power"`
		Brightness   int  `json:"brightness"`
		Mode         int  `json:"mode"`
		Speed        int  `json:"speed"`
		FanSpeed     []int`json:"fans"`
		Rate         []int`json:"rates"`
		Target       []int`json:"targets"`
		BatteryLimit int  `json:"batterylimit"`
	}

	if err := json.Unmarshal(output, &data); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to parse response: %v\n", err)
		os.Exit(1)
	}

	responseText := []string{
		"RGB:    ON  (mode=" + strconv.Itoa(data.Mode) + ", speed=" + strconv.Itoa(data.Brightness) + ")",
		"FAN:    " + formatFanSpeed(data.FanSpeed),
		"BAT:    Charge limit = " + strconv.Itoa(data.BatteryLimit) + "%",
	}

	fmt.Println(strings.Join(responseText, "\n"))
}

func formatFanSpeed(speeds []int) string {
	if len(speeds) == 0 {
		return "OFF"
	}
	return fmt.Sprintf("%d%% (%v)", speeds[0], speeds[1:])
}
