# Sven Co-op script: func_projectile_shooter

This script implements an entity for use in maps, `func_projectile_shooter`, which can be used to create and fire arbitrary projectiles either cyclically (when triggered) or repeated on a timer (switchable).

The projectiles can consist of a model or sprite, a sound for travel, firing, and impact, specific speed and weight, damage on impact, and triggers on firing and impact, and lots more.

## Installation

This script needs to be at game path "scripts/maps/projectile_shooter". Then in a map do **one** of the following:

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

## Shooter entity

Include "projectile_shooter.fgd" in your favourite map editor, which will provide you with point entity `func_projectile_shooter` for your map.

The shooter entity is invisible, non-moving, non-solid, and unsized (like an `info_target`), which acts as the initial position, angle, and properties template for projectile entities it fires.

**Important:** All sound related properties may currently need to be accompanied with a `custom_precache` entity to ensure custom sound files get precached. (This is a limitation in the game as to how scripted entities can precache sounds.)

### Spawn flags

#### Timed mode

Activate this flag to automatically fire projectiles on a timed loop. Triggering this entity with on, off, or toggle will start, stop, or switch firing respectively.

If disabled a projectile will fire when this entity is triggered.

#### Timed mode: Start on

When the above **Timed mode** flag is enabled this shooter will begin firing immediately.

If disabled projectiles will not fire until this entity is triggered with on (start) or toggle (switch).

### Properties

As the vast majority of properties are rather self explanatory, descriptions will only be mentioned for those with at least some ambiguity.

#### Time Between Fires

`float fire_timer`, default `4`.

When the **Timed mode** flag is enabled this specifies the timed interval (seconds) in which a projectile will be fired. E.g. `4` means fire a projectile every 4 seconds.

#### Projectile: Sound

`string projectile_sound`, default unset.

Specify a sound file to play in loop attached to the projectile.

#### Projectile: Min/Max hull size (X Y Z)

`vector projectile_minhullsize`, default `0 0 0`.
`vector projectile_maxhullsize`, default `0 0 0`.

These define the bounding box for the projectile's impact collision.

The projectiles are solid from the moment they are spawned so it is important to position this shooter entity in a non-solid space so that the projectile will fit without immediately becoming stuck in a solid brush such as a wall, floor, ceiling, etc.

E.g. if your projectile is 8³ units size (`-4 -4 -4` min and `4 4 4` max) then this shooter entity will need to be more than 4 units (`> 4.0`) away from anything solid (both brush and point based), otherwise when the projectile is launched it'll just collide immediately and vanish.

Leaving this as the default zero size means the projectile will have pinpoint precision like the majority of bullet based weapons, though the shooter entitiy should still not touch any solids. (Even `0.001` distance away from a wall would suffice.)

#### Projectile: Gravity

`float projectile_gravity`, default `1`.

Obviously this is a multiplier for gravity on the projectile. E.g. `1` means normal and `0.5` means half.

This only needs a mention as a gravity of `0` will set the projectile's move type to `BOUNCEMISSILE` instead of `BOUNCE`.

The physics for projectiles impacted by gravity is still work in progress.

#### Projectile: Drag

`float projectile_drag`, default `1`.

Simply an alias for friction, which determines how the projectile slows down as it travels.

## Projectile entity

When a `func_projectile_shooter` fires a projectile this will be an `env_projectile` entity. Its not available in the FGD because the projectile would just spawn and disappear the instant a map begins to run. (Which would be pointless.)

Almost all of the shooter's properties are copied to this along with origin, angles, and rendering properties. Its owner entity will be set to the shooter entity, unless you were to programmatically create a projectile entity at runtime or with a `trigger_createentity`.

The projectile entity is passed as both the activator and caller for on fire and on impact triggers.

## Wish list

The following features have not been implemented:

* Custom render properties for the on fire and on impact sprites.
* Random cone of fire. (Workaround: The projectile copies the angle of its shooter when fired so adjusting the shooter angles at your pleasure during runtime would work.)
* Trail/tracer sprite.
* Any form of homing/tracing to a target entity/position.
