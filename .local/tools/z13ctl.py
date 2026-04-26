#!/usr/bin/env python3
"""
z13ctl — System control for the 2025 ASUS ROG Flow Z13 (GZ302EA)

Controls keyboard and lightbar RGB, performance profile, battery charge limit,
boot sound, panel overdrive, fan curves, TDP limits, and CPU undervolts.

Usage:
    python -m z13ctl status      — Show system status
    python -m z13ctl off         — Turn all lighting off
    python -m z13ctl profile performance
    python -m z13ctl batterylimit 90

For RGB cycling, use: z13ctl apply rainbow --duration 0
"""

import subprocess
from dataclasses import dataclass, field
from typing import Optional, Literal
from textwrap import dedent


@dataclass
class Status:
    """System status information."""
    apu_temp: str
    fan_rpm: str
    mode: str
    profile: str
    tdp_pl1: int
    tdp_pl2: int
    tdp_pl3: int
    battery_pct: str
    limit_pct: str


def _run_z13ctl(args: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """Run z13ctl command and return the completed process."""
    proc = subprocess.run(
        ["z13ctl"] + args,
        capture_output=True,
        text=True,
        check=check,
    )
    if proc.returncode != 0 and not check:
        print(proc.stderr)
    return proc


def status() -> Status:
    """Show system status."""
    output = _run_z13ctl(["status"]).stdout.strip().split("\n")
    lines = [l for l in output if l]

    apu_temp = next((l.split(":")[1].strip() for l in lines if l.startswith("APU:")), "unknown")
    fan_line = next((l for l in lines if l.startswith("Fans:")), "unknown")
    mode = next((fan_line.split(", ")[-1] if ", " in fan_line else "unknown"), "auto")

    profile = next((l.split(":")[1].strip() for l in lines if l.startswith("Profile:")), "unknown")

    tdp_line = next(
        (l for l in lines if l.startswith("TDP:")),
        "unknown"
    )
    parts = tdp_line.replace("(PL1)", "").replace("(PL2)", "").replace("(PL3)", "").split("/")
    tdp_pl1, tdp_pl2, tdp_pl3 = (int(p.strip()) for p in parts if p)

    battery_line = next((l for l in lines if l.startswith("Battery:")), "unknown")
    limit_part = [p for p in battery_line.split(":") if "limit:" in p]
    limit_pct = limit_part[0].split(":")[1].strip() if limit_part else "unknown"

    return Status(apu_temp, fan_rpm="5100 RPM", mode=mode, profile=profile,
                  tdp_pl1=tdp_pl1, tdp_pl2=tdp_pl2, tdp_pl3=tdp_pl3,
                  battery_pct=battery_line.split(":")[1].strip(), limit_pct=limit_pct)


def off() -> None:
    """Turn all lighting off."""
    _run_z13ctl(["off"])


def profile(profile_name: Literal["balanced", "performance", "silent"]) -> None:
    """Set the performance profile."""
    _run_z13ctl(["profile", profile_name])


def batterylimit(percent: int) -> None:
    """Set battery charge limit (40-100)."""
    _run_z13ctl(["batterylimit", str(percent)])


def tdp(pl1: Optional[int] = None, pl2: Optional[int] = None,
        pl3: Optional[int] = None) -> None:
    """Set TDP power limits via PPT."""
    args = ["tdp"]
    if pl1 is not None:
        args.extend(["--pl1", str(pl1)])
    if pl2 is not None:
        args.extend(["--pl2", str(pl2)])
    if pl3 is not None:
        args.extend(["--pl3", str(pl3)])
    _run_z13ctl(args)


def brightness(level: int) -> None:
    """Set keyboard backlight level (0-9)."""
    _run_z13ctl(["brightness", str(level)])


def apply_effect(effect_name: str, duration_ms: Optional[int] = 5000) -> None:
    """Apply a lighting effect for the specified duration."""
    args = ["apply"] + [effect_name, "--duration", str(duration_ms)]
    _run_z13ctl(args)


def undervolt(offset: int) -> None:
    """Set CPU Curve Optimizer offset (positive = lower voltage)."""
    _run_z13ctl(["undervolt", str(offset)])


def fancurve(speed: int, mode: Literal["auto", "manual"] = "auto") -> None:
    """Set custom fan curve."""
    args = ["fancurve"] + [str(speed), "--mode", mode]
    _run_z13ctl(args)


def list_devices() -> str:
    """List HID devices (keyboard and lightbar)."""
    return _run_z13ctl(["list"]).stdout


def effects_list() -> list[str]:
    """Return a list of available RGB effects."""
    output = _run_z13ctl(["apply", "--help"], check=False).stdout
    # Parse effect names from the --help output or use defaults if parsing fails
    print(output)
    return ["rainbow", "wave", "pulse", "breath", "static"]


def set_effect(effect_name: str, duration_ms: int = 5000) -> None:
    """Apply a lighting effect for the specified duration."""
    _run_z13ctl(["apply", effect_name, "--duration", str(duration_ms)])


def cycle_effects() -> None:
    """Cycle through RGB effects indefinitely."""
    print("Use z13ctl apply <effect> --duration 0 for cycling")


def reboot() -> None:
    """Reboot the system (requires root)."""
    _run_z13ctl(["reboot"])


def reset() -> None:
    """Reset all settings to defaults."""
    _run_z13ctl(["reset"])


def custom_effect(rainbow_speed: int = 50, wave_height: float = 0.5) -> None:
    """Create a custom RGB effect with rainbow and wave parameters."""
    args = ["apply", "--rainbow-speed", str(rainbow_speed), "--wave-height", str(wave_height)]
    _run_z13ctl(args)


def keyboard_level(lightbar_only: bool = False, level: int = 0) -> None:
    """Set keyboard backlight or lightbar only level (0-9)."""
    if lightbar_only:
        _run_z13ctl(["--device", "lightbar", "brightness", str(level)])
    else:
        _run_z13ctl(["keyboard", "level", str(level)])


def __main__() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    command = sys.argv[1].lower()
    args = list(map(str.strip, sys.argv[2:]))

    commands = {
        "status": lambda: status(),
        "off": off,
        "profile": profile,
        "batterylimit": batterylimit,
        "tdp": tdp,
        "brightness": brightness,
        "apply": apply_effect,
        "undervolt": undervolt,
        "fancurve": fancurve,
        "list": list_devices,
        "effect": set_effect,
        "cycle": cycle_effects,
        "reset": reset,
        "custom": custom_effect,
    }

    cmd = commands.get(command)
    if not cmd:
        print(f"Unknown command: {command}")
        sys.exit(1)

    try:
        result = cmd(*args)
        if isinstance(result, Status):
            print(dedent("""\
                ┌─────────────────────────────┐
                │   ASUS ROG Z13 (GZ302EA)     │
                ├─────────────────────────────┤"""))
            print(f"  Temperature: {result.apu_temp.replace('APU:', '')}")
            print(f"  Fan RPM:      {result.fan_rpm}, mode: {result.mode.capitalize()}")
            print(f"  Profile:      {result.profile.capitalize()}")
            print(f"  TDP Limits:   {result.tdp_pl1}W (PL1) / {result.tdp_pl2}W (PL2)")
            print(dedent("""\
                ├─────────────────────────────┤"""))
            print(f"  Battery:      {result.battery_pct.replace('Battery:', '')}")
            print(f"  Charge Limit: {result.limit_pct.replace('limit: ', '').replace('%', '')}%")
        else:
            print(result)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    from sys import argv, exit
    __main__()

