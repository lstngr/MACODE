# Negative Triangularity
The `work` folder contains a set of configurations generating triangular
configurations.

- `validation` configurations, where the some previously obtained snowflake
    structures were reproduced.
- `triangularSingle` configurations, with positive and negative triangularities
    displaying a single null point. Two approaches are investigated:
    - `unicoil` attempts to create triangular configurations with a single
        divertor coil, moved horizontally compared to a standard single null
        configuration.
    - `quadcoil` adds three other coils to control triangularity on the upper
        part of the domain (opposite to the null point), while trying to
        maintain flux expansion reasonable in this region.
- `triangularLower` uses three coils to hold upper triangularity close to zero,
    while a lower null point is shifted, changing the lower triangularity. This
    configuration does not display flux expansion on the top of the domain.
- `triangularDouble` investigates double null configurations where both null
    points are moved horizontally, increasing the overall triangularity to
    larger values than all previous configurations. It uses two divertor coils.
    Additional coils could be added in the midplane to control magnetic field
    line compression.

