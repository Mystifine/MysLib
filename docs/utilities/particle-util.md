# ParticleUtil

Particle and beam effect management utilities.

## Methods

### emitParticle

Emits a burst from a `ParticleEmitter`, scaled by the player's graphics quality. **Client-only function**.

```lua
MysLib.ParticleUtil.emitParticle(emitter, 50)
MysLib.ParticleUtil.emitParticle(emitter)      -- 16, the engine's default
```

- On **Automatic** quality the full amount is emitted.
- On a fixed quality level `n` (1–10), the amount is scaled by `n / 10` and rounded down.
- Any positive amount emits **at least 1** particle, so small bursts stay visible on low settings.
- An amount of `0` or less emits nothing.

---

### playParticleEffects

Plays all particle emitters in an instance and its descendants. Each emitter can be configured with attributes:

| Attribute | Default | Meaning |
|---|---|---|
| `EmitCount` | `Rate` | Particles emitted once the delay has passed (scaled as in `emitParticle`) |
| `EmitDelay` | `0` | Seconds to wait before emitting |
| `EmitDuration` | `0` | Seconds to keep the emitter `Enabled` after the burst |

```lua
MysLib.ParticleUtil.playParticleEffects(part)
```

An attribute holding a non-number value is ignored with a warning, and an emitter that fails to emit is skipped without affecting the others.

---

### setParticlesEnabled

Enables or disables all particle emitters in a part.

```lua
MysLib.ParticleUtil.setParticlesEnabled(part, true)   -- Enable
MysLib.ParticleUtil.setParticlesEnabled(part, false)  -- Disable
```

---

### setBeamsEnabled

Enables or disables all beam emitters in a part.

```lua
MysLib.ParticleUtil.setBeamsEnabled(part, true)   -- Enable
MysLib.ParticleUtil.setBeamsEnabled(part, false)  -- Disable
```

---

### clearAllParticles

Clears all live particles from every particle emitter in a part and its descendants.

```lua
MysLib.ParticleUtil.clearAllParticles(part)
```

## Examples

### Trigger Effect

```lua
local effect = workspace:FindFirstChild("ExplosionEffect")
MysLib.ParticleUtil.playParticleEffects(effect)
```

### Hide Effects

```lua
local spell = workspace:FindFirstChild("SpellEffect")
MysLib.ParticleUtil.setParticlesEnabled(spell, false)
```

### Cleanup Effects

```lua
local oldEffect = workspace:FindFirstChild("OldEffect")
MysLib.ParticleUtil.clearAllParticles(oldEffect)
oldEffect:Destroy()
```
