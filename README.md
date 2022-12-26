# Sven Co-op script: func_projectile_shooter

This script implements an entity for use in maps, `func_projectile_shooter`, which can be used to create and fire arbitrary projectiles either cyclically or repeated on a timer.

The projectiles can consist of a model or sprite, a sound for firing and impact, specific speed and weight, damage on impact, and triggers on firing and impact.

## Installation

This script needs to be at game path "scripts/maps/projectile-shooter". Then in a map do **one** of the following:

### With your map configuration

Add a line to your map configuration entry:

```
map_script projectile_shooter
```

### Include in your existing map script

If you have a main map script you can include this script as follows:

```
#include projectile_shooter
```

However if your map script has a `MapInit()` function you must also call the projectile shooter initialisation in there, for example:

```
/**
 * Map initialisation handler.
 * @return void
 */
void MapInit()
{
    g_Module.ScriptInfo.SetAuthor("Your \"Alias\" Name");
    g_Module.ScriptInfo.SetContactInfo("www.example.com");

    // Initialise projectile shooter
    ProjectileShooter::Init();
}
```

## Point entity

Add a point entity with classname `func_projectile_shooter`:

*Instructions TBD.*
