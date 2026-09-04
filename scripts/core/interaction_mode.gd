## Shared, typed interaction modes used to route input intent.
## Kept tiny and dependency-free; consumed via preload by the coordinator, targeting and firing.
enum Mode { ORBIT, TARGETING, FIRING }

const DEFAULT_MODE := Mode.TARGETING