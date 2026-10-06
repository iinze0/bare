# Changelog

## 3.2

- CPU tick: processor boost policy 100, wireless adapter power saving off.
- Telemetry tick: EnablePrefetcher 0 and EnableSuperfetch 0, on top of the SysMain service disable.
- Idle-off: optional `bcdedit` dynamic tick disable. Asks for yes. Needs a reboot. Can make timing less stable.

## 3.1

- Hybrid policy, service split, memory compression off, Nagle off.
