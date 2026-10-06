# Power and CPU

bare duplicates the Ultimate performance scheme when Windows has it (`e9a42b02-d5df-448d-aa00-03f14749eb61`). If that scheme is missing, it uses High performance (`8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`).

On AC it then sets:

- Processor throttle minimum 100
- Processor throttle maximum 100
- Core parking minimum cores 100
- Core parking maximum cores 100
- Sleep standby idle 0
- USB selective suspend off

100% minimum means the plan will not ask the CPU to downclock while on wall power. It does not raise the chip past its normal boost. The cooler, power limit, and Windows still cap it. Idle states stay on in option 1 and 2 so unused cores can sleep between frames. Option 3 turns idle off. That is the one that holds the CPU awake.

Laptops on battery are not retuned. These indexes are AC only.
