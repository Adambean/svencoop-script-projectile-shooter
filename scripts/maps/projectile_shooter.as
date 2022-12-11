/**
 * General purpose "func_projectile_shooter" and "env_projectile" entities.
 * By Adam "Adambean" Reece
 *
 * This is a point entity that will create and launch a projectile, either by trigger (cyclic) or timed.
 * The projectile can be made up of a model and/or sprite with a set speed, weight, and damage (amount and type) on
 * impact.
 *
 * See accompanying "README.md" and "projectile_shooter.fgd" for usage.
 */

/**
 * Map initialisation handler.
 * @return void
 */
void MapInit()
{
    g_Module.ScriptInfo.SetAuthor("Adam \"Adambean\" Reece");
    g_Module.ScriptInfo.SetContactInfo("www.svencoop.com");

    ProjectileShooter::Init();
}

namespace ProjectileShooter
{
    /** @var bool g_isInitialised Is initialised. */
    bool g_isInitialised = false;

    /**
     * Initialise.
     * @return void
     */
    void Init()
    {
        if (g_isInitialised) {
            g_Game.AlertMessage(at_warning, "[ProjectileShooter] Already initialised.\n");
            return;
        }

        g_CustomEntityFuncs.RegisterCustomEntity("ProjectileShooter::CFuncProjectileShooter", "func_projectile_shooter");
        g_CustomEntityFuncs.RegisterCustomEntity("ProjectileShooter::CEnvProjectile", "env_projectile");
        g_isInitialised = true;
    }

    /**
     * Entity: func_projectile_shooter
     * A shooter for `env_projectile` entities.
     */
    final class CFuncProjectileShooter : ScriptBaseEntity
    {
        /** @const int Fire a projectile repeatedly on a timer until stopped instead of cyclically. */
        const int SF_TIMED = 1<<0;

        /** @var bool m_fTimed Timed mode. */
        bool m_fTimed = false;

        /** @var bool m_fState State. (Only used in timed mode.) */
        bool m_fState = false;

        /**
         * Key value data handler.
         * @param  string szKey   Key
         * @param  string szValue Value
         * @return bool
         */
        bool KeyValue(const string& in szKey, const string& in szValue)
        {
            return BaseClass.KeyValue(szKey, szValue);
        }

        /**
         * Spawn.
         * @return void
         */
        void Spawn()
        {
            if (self.IsBSPModel()) {
                g_Game.AlertMessage(at_warning, "[CFuncProjectileShooter] Entity cannot be a brush, removing.\n");
                g_EntityFuncs.Remove(self);
                return;
            }

            m_fTimed = self.pev.spawnflags & ProjectileShooter::SF_TIMED;
        }

        /**
         * Use handler.
         * @param  CBaseEntity@ pActivator Activator entity
         * @param  CBaseEntity@ pCaller    Caller entity
         * @param  USE_TYPE     useType    Use type
         * @param  float        flValue    Use value
         * @return void
         */
        void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
        {
            if (m_fTimed) {
                /** @var bool fState Current state prior to changing. */
                bool fState = m_fState;

                switch (useType) {
                    case USE_ON:
                        m_fState = true;
                        break;

                    case USE_OFF:
                        m_fState = false;
                        break;

                    case USE_SET:
                        m_fState = (flValue != 0.0);
                        break;

                    case USE_TOGGLE:
                        m_fState = !m_fState;
                        break;

                    case USE_KILL:
                        g_EntityFuncs.Remove(self);
                        return;
                }

                if (m_fState == fState) {
                    return; // Nothing to change
                }
            } else {
                Fire();
            }
        }

        /**
         * Fire a projectile.
         * @return CEnvProjectile@ Projectile entity
         */
        CEnvProjectile@ Fire()
        {

        }

        /**
         * Timed mode think.
         * @return void
         */
        void TimedThink()
        {
            if (g_Engine.time < self.pev.nextthink) {
                return;
            }

            Fire();
            self.pev.nextthink = g_Engine.time + self.pev.delay;
        }
    }

    /**
     * Entity: env_projectile
     * A projectile that has been fired from a `func_projectile_shooter`.
     */
    final class CEnvProjectile : ScriptBaseEntity
    {
        /**
         * Key value data handler.
         * @param  string szKey   Key
         * @param  string szValue Value
         * @return bool
         */
        bool KeyValue(const string& in szKey, const string& in szValue)
        {
            return BaseClass.KeyValue(szKey, szValue);
        }

        /**
         * Spawn.
         * @return void
         */
        void Spawn()
        {
            if (self.IsBSPModel()) {
                g_Game.AlertMessage(at_warning, "[CEnvProjectile] Entity cannot be a brush, removing.\n");
                g_EntityFuncs.Remove(self);
                return;
            }
        }
    }
}
