# ParticleUtil

Particle and beam effect management utilities.

## Methods

### emitParticle

Emits a single particle from a specific location.

```lua
MysLib.ParticleUtil.emitParticle(particle, part)
```

---

### playParticleEffects

Plays all particle emitters in a part and its descendants.

```lua
MysLib.ParticleUtil.playParticleEffects(part)
```

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

Clears all particles and beams from a part and its descendants.

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
