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
     * Convert a sound radius option to an attenuation.
     * @param  int   iRadius Radius
     * @return float         Attenuation
     */
    float SoundRadiusOptionToAttenuation(int iRadius)
    {
        switch (iRadius) {
            case 0: // Everywhere
                return ATTN_NONE;

            case 1: // Small (~384)
                return ATTN_IDLE;

            case 2: // Medium (~768)
                return ATTN_STATIC;

            case 3: // Large (~1,536)
                return ATTN_NORM;
        }

        // Assume medium if unknown
        return ATTN_STATIC;
    }

    /**
     * Entity: func_projectile_shooter
     * A shooter for `env_projectile` entities.
     */
    final class CFuncProjectileShooter : ScriptBaseEntity
    {
        /*
        ------------------------------------------------------------------------
            Constants
        ------------------------------------------------------------------------
         */

        /** @const int Fire a projectile repeatedly on a timer until stopped instead of cyclically. */
        const int SF_TIMED = 1<<0;

        /** @const int When timed mode is enabled, start firing immediately. */
        const int SF_TIMED_START_ON = 1<<1;



        /*
        ------------------------------------------------------------------------
            Runtime variables
        ------------------------------------------------------------------------
         */

        /** @var bool m_fTimed Timed mode. */
        bool m_fTimed = false;

        /** @var bool m_fState State. (Timed mode only.) */
        bool m_fState = false;



        /*
        ------------------------------------------------------------------------
            Map variables
        ------------------------------------------------------------------------
         */

        // Operational

        /** @var float m_flFireTimer Time between fires. (Timed mode only. Obviously.) */
        float m_flFireTimer = 3.0;

        // Projectile: Model

        /** @var string m_szModel Projectile: Model file. */
        string m_szModel = "";

        /** @var int m_iModelSkin Projectile: Model skin. */
        int m_iModelSkin = 0;

        /** @var int m_iModelBody Projectile: Model body. */
        int m_iModelBody = 0;

        /** @var string m_szModelSequenceName Projectile: Model sequence name. */
        string m_szModelSequenceName = "idle";

        /** @var int m_iModelSequence Projectile: Model sequence number. */
        int m_iModelSequence = 0;

        /** @var float m_flModelScale Projectile: Model scale. */
        int m_flModelScale = 1.0;

        // Projectile: Sprite

        /** @var string m_szSprite Projectile: Sprite file. */
        string m_szSprite = "";

        /** @var float m_flSpriteFramerate Projectile: Sprite frame rate.*/
        float m_flSpriteFramerate = 10.0;

        /** @var MAP_VP_TYPE m_iSpriteVpType Projectile: Sprite map viewport type. */
        MAP_VP_TYPE m_iSpriteVpType = MAP_VP_DEFAULT;

        /** @var float m_flSpriteScale Projectile: Sprite scale. */
        float m_flSpriteScale = 1.0;

        // Projectile: Sound

        /** @var string m_szSound Projectile: Sound file. */
        string m_szSound = "";

        /** @var float m_flSoundVolume Projectile: Sound volume. */
        float m_flSoundVolume = VOL_NORM;

        /** @var float m_flSoundRadius Projectile: Sound radius. */
        float m_flSoundRadius = ATTN_STATIC;

        // Projectile: Properties

        /** @var float m_flSpeed Projectile: Speed. (Units per second.) */
        float m_flSpeed = 16.0;

        /** @var float m_flDmg Projectile: Damage on impact. */
        float m_flDmg = 0.0;

        /** @var float m_flArmorDmg Projectile: Damage on impact. (To armor.) */
        float m_flArmorDmg = 0.0;

        /** @var DMG m_iDamageType Projectile: Damage on impact type. */
        DMG m_iDamageType = DMG_GENERIC;

        // Event: On fire

        /** @var string m_szFireTarget On fire: Trigger target. */
        string m_szFireTarget = "";

        /** @var USE_TYPE m_iFireTriggerState On fire: Trigger state. */
        USE_TYPE m_iFireTriggerState = USE_TOGGLE;

        /** @var string m_szFireSound On fire: Sound file. */
        string m_szFireSound = "";

        /** @var float m_flFireSoundVolume On fire: Sound volume. */
        float m_flFireSoundVolume = VOL_NORM;

        /** @var float m_flFireSoundRadius On fire: Sound radius. */
        float m_flFireSoundRadius = ATTN_STATIC;

        // Event: On impact

        /** @var string m_szImpactTarget On impact: Trigger target. */
        string m_szImpactTarget = "";

        /** @var USE_TYPE m_iImpactTriggerState On impact: Trigger state. */
        USE_TYPE m_iImpactTriggerState = USE_TOGGLE;

        /** @var string m_szImpactSound On impact: Sound file. */
        string m_szImpactSound = "";

        /** @var float m_flImpactSoundVolume On impact: Sound volume. */
        float m_flImpactSoundVolume = VOL_NORM;

        /** @var float m_flImpactSoundRadius On impact: Sound radius. */
        float m_flImpactSoundRadius = ATTN_STATIC;



        /*
        ------------------------------------------------------------------------
            Functions
        ------------------------------------------------------------------------
         */

        /**
         * Key value data handler.
         * @param  string szKey   Key
         * @param  string szValue Value
         * @return bool
         */
        bool KeyValue(const string& in szKey, const string& in szValue)
        {
            if (szKey == "fire_timer") {
                m_flFireTimer = Math.max(0.01f, atof(szValue));
                return true;
            }

            if (szKey == "model") {
                m_szModel = szValue;
                return true;
            }

            if (szKey == "model_skin") {
                m_iModelSkin = Math.max(0, atoi(szValue));
                return true;
            }

            if (szKey == "model_body") {
                m_iModelBody = Math.max(0, atoi(szValue));
                return true;
            }

            if (szKey == "model_sequencename") {
                m_szModelSequenceName = szValue;
                return true;
            }

            if (szKey == "model_sequence") {
                m_iModelSequence = Math.max(0, atoi(szValue));
                return true;
            }

            if (szKey == "model_scale") {
                m_flModelScale = Math.max(0.001f, atof(szValue));
                return true;
            }

            if (szKey == "sprite") {
                m_szSprite = szValue;
                return true;
            }

            if (szKey == "sprite_framerate") {
                m_flSpriteFramerate = Math.max(0.01f, atof(szValue));
                return true;
            }

            if (szKey == "sprite_vp_type") {
                m_iSpriteVpType = cast<MAP_VP_TYPE>(atoi(szValue));
                return true;
            }

            if (szKey == "sprite_scale") {
                m_flSpriteScale = Math.max(0.001f, atof(szValue));
                return true;
            }

            if (szKey == "sound") {
                m_szSound = szValue;
                return true;
            }

            if (szKey == "sound_volume") {
                m_flSoundVolume = Math.min(1.0f, Math.max(0.0f, atof(szValue)));
                return true;
            }

            if (szKey == "sound_radius") {
                m_flSoundRadius = ProjectileShooter::SoundRadiusOptionToAttenuation(atoi(szValue));
                return true;
            }

            if (szKey == "speed") {
                m_flSpeed = Math.max(0.001f, atof(szValue));
                return true;
            }

            if (szKey == "dmg") {
                m_flDmg = atof(szValue); // Minus numbers allowed to heal/repair
                return true;
            }

            if (szKey == "armordmg") {
                m_flArmorDmg = atof(szValue); // Minus numbers allowed to heal/repair
                return true;
            }

            if (szKey == "damagetype") {
                m_iDamageType = cast<DMG_TYPE>(atoi(szValue));
                return true;
            }

            if (szKey == "fire_target") {
                m_szFireTarget = szValue;
                return true;
            }

            if (szKey == "fire_triggerstate") {
                m_iFireTriggerState = cast<USE_TYPE>(atoi(szValue));
                return true;
            }

            if (szKey == "fire_sound") {
                m_szFireTarget = szValue;
                return true;
            }

            if (szKey == "fire_sound_volume") {
                m_flFireSoundVolume = Math.min(1.0f, Math.max(0.0f, atof(szValue)));
                return true;
            }

            if (szKey == "fire_sound_radius") {
                m_flFireSoundRadius = ProjectileShooter::SoundRadiusOptionToAttenuation(atoi(szValue));
                return true;
            }

            if (szKey == "impact_target") {
                m_szImpactTarget = szValue;
                return true;
            }

            if (szKey == "impact_triggerstate") {
                m_iImpactTriggerState = cast<USE_TYPE>(atoi(szValue));
                return true;
            }

            if (szKey == "impact_sound") {
                m_szImpactTarget = szValue;
                return true;
            }

            if (szKey == "impact_sound_volume") {
                m_flImpactSoundVolume = Math.min(1.0f, Math.max(0.0f, atof(szValue)));
                return true;
            }

            if (szKey == "impact_sound_radius") {
                m_flImpactSoundRadius = ProjectileShooter::SoundRadiusOptionToAttenuation(atoi(szValue));
                return true;
            }

            return BaseClass.KeyValue(szKey, szValue);
        }

        /**
         * Spawn.
         * @return void
         */
        void Spawn()
        {
            Precache();

            if (self.IsBSPModel()) {
                g_Game.AlertMessage(at_warning, "[CFuncProjectileShooter] Entity cannot be a brush, removing.\n");
                g_EntityFuncs.Remove(self);
                return;
            }

            if (m_szModel.isEmpty() and m_szSprite.isEmpty()) {
                g_Game.AlertMessage(at_warning, "[CFuncProjectileShooter] Entity must have at least a model or sprite, removing.\n");
                g_EntityFuncs.Remove(self);
                return;
            }

            m_fTimed = (self.pev.spawnflags & ProjectileShooter::SF_TIMED);
            m_fState = (self.pev.spawnflags & ProjectileShooter::SF_TIMED_START_ON and m_fTimed);
        }

        /**
         * Precache.
         * @return void
         */
        void Precache()
        {
            if (!m_szModel.isEmpty()) {
                g_Game.PrecacheModel(this, m_szModel);
            }

            if (!m_szSprite.isEmpty()) {
                g_Game.PrecacheModel(this, m_szSprite);
            }

            if (!m_szSound.isEmpty()) {
                g_SoundEngine.PrecacheSound(this, m_szSound);
            }

            if (!m_szFireSound.isEmpty()) {
                g_SoundEngine.PrecacheSound(this, m_szFireSound);
            }

            if (!m_szImpactSound.isEmpty()) {
                g_SoundEngine.PrecacheSound(this, m_szImpactSound);
            }
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
            if (!m_fTimed) {
                Fire();
                return;
            }

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
        }

        /**
         * Fire a projectile.
         * @return CEnvProjectile@ Projectile entity
         */
        CEnvProjectile@ Fire()
        {
            @CEnvProjectile pProjectile = CreateEntity("env_projectile", , true);
            return pProjectile;
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
