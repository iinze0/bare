# Power

Option 9 duplicates Ultimate performance (`e9a42b02-d5df-448d-aa00-03f14749eb61`) when Windows allows it, then activates it. If that scheme is missing from `powercfg /list`, it uses High performance (`8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`).

AC values set:

- Processor throttle minimum 100
- Processor throttle maximum 100
- Core parking minimum cores 100

This does not raise the chip past its normal boost. Battery indexes are not changed.

Option 10 is option 9 plus processor idle disable. The CPU does not enter idle states. More heat, more power, and frames can drop if the cooler cannot keep up. Laptops should leave it off. The apply step asks for `yes` when this tick is on.
