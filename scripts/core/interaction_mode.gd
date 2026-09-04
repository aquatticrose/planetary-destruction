## Shared, typed interaction modes used to route aim intent.
## Kept tiny and dependency-free; consumed via preload by the coordinator,
## aim controller and tests.
enum Mode { CROSSHAIR, TARGETING }

const DEFAULT_MODE := Mode.CROSSHAIR