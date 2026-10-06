# Changelog

## 3.4

- CPU settings written after the first plan switch are applied again. Before this, boost policy and hybrid policy could sit unused until the next manual plan change.
- Revert clears priority separation, power throttling, multiplane overlay, Nagle, prefetch, memory compression, and dynamic tick.
- Scan prints EnablePrefetcher and Win32PrioritySeparation.

## 3.3

- Privacy tick expanded. Camera and microphone stay.
