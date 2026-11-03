# Changelog

## 0.2.8

Drop-in upgrade: no public function, field or alias was removed or renamed.

### Fixed

- **Hitbox (projectile):** the ray grid was offset to the right of the projectile's path by half its width, so hits on the left were missed. It is now centred on `cframe` and spans exactly `width` × `height`.
- **Hitbox (projectile):** a `width` or `height` below 1 stud produced NaN ray positions, so thin projectiles never hit. Any size, including 0, now works.
- **Hitbox (projectile):** when several rays hit in one frame, the nearest hit is reported instead of whichever ray came first in the grid. Every ray now advances the same distance per frame.
- **Hitbox (projectile):** calling `Start()` from inside `onHit` restarts the projectile instead of being undone straight away.
- **Hitbox:** a misconfigured or failing hitbox used to error every frame and stop the hitboxes after it from running. It is now stopped with a single warning, and the others keep running.
- **Hitbox:** starting or destroying hitboxes from inside `onHit` no longer runs new hitboxes early or skips existing ones.
- **Hitbox:** `Cast()`/`Start()` on a destroyed hitbox no longer throws. Destroying a hitbox inside `onHit` stops the rest of that check's hits being delivered.
- **Hitbox:** `getClosestTarget` skips models without a `PrimaryPart` instead of erroring. `raycast` debug visuals now last 0.5 s by default instead of 10 s.
- **Signal:** `Wait()` returns the exact values passed to `Fire()`; tables were previously copied and lost their metatables. It also no longer leaves a `BindableEvent` behind for each wait.
- **Signal:** a connection disconnected during `Fire()` is no longer called in that same `Fire()`.
- **Maid:** if a task errored, the remaining tasks were never cleaned and a second `Destroy()` re-ran earlier tasks. Every task now runs exactly once, and an error is printed as a warning with a traceback. Calling `Destroy()` from inside a task no longer overflows the stack.
- **Maid:** giving the same task again under its own key no longer destroys it.
- **Debris:** a cleanup that errored, yielded, or called `AddItem`/`RemoveItem` could run items twice or remove the wrong item.
- **AttributeModifier:** the documented attribute usage (`AttributeModifier.new(part, "MyAttribute")`) used to error. Names that aren't properties now read and write attributes, and a missing attribute counts as 0 when incrementing. Property usage such as `WalkSpeed` behaves as before.
- **AttributeModifier:** values changed by other code are no longer overwritten with a stale value, and calling an `Undo()` twice no longer reverts twice. The methods return a harmless undo after the modifier is destroyed instead of `nil`.
- **Bootstrapper:** the pre-0.2.7 call form `loadModule(name, module, ...)` errored after the signature change in 0.2.7. It is accepted again. A module that returns a non-table, or throws a non-string error, is now reported instead of crashing the loader.
- **ParticleUtil.emitParticle:** any positive amount now emits at least 1 particle, because bursts scaled below 1 on low graphics settings emitted nothing. Calling it without an amount on a fixed quality level used to error.
- **ParticleUtil.playParticleEffects:** one emitter with a bad attribute value, or one that failed to emit (for example when called on the server), used to error every frame and stop the other emitters.
- **GeneralUtil.Heartbeat / Stepped:** a connection disconnected earlier in the same frame is no longer called. Timing uses `os.clock()`, so client clock re-syncs can't pause callbacks. Callback errors now include a traceback.
- **GeneralUtil.yieldWhileCondition:** the documented form, which takes a bare condition function, used to error.
- **waitForChild:** now finds a child that is renamed after being added. It returns a child that arrives in the same frame the parent is removed, and it can wait on `game`.
- **StringUtil:** `abbrev` carries into the next suffix (`999999` → `"1.0M"`, not `"1000.0K"`) and handles infinity. `addCommas` handles negative numbers (`-100` was `"-,100"`) and very large numbers. `formatTime` handles negative durations.
- **StringUtil.RichText:** colours are rounded to the nearest 0–255 value instead of truncated.
- **MathUtil.truncate:** now rounds negative numbers toward zero (`-3.14159` → `-3.14`, was `-3.15`), and floating point error no longer drops a digit (`0.29` → `0.29`, was `0.28`).
- **TableUtil.deepCopy:** a table that references itself no longer overflows the stack.
- **ModelUtil.getModelLargestPart:** a non-part child, such as a Humanoid, no longer resets the result, and parts at any depth are compared correctly.
- **PhysicsUtil.Orientation:** priorities never took effect, so orientations stacked up on a part. Equal or lower priorities are now replaced, as documented.
- **PhysicsUtil.Velocity / Orientation:** the priority attribute is set before the attachment is parented. A same-named attachment without a priority no longer errors.
- **PlayerUtil.isCharacterAlive:** finds the Humanoid by class rather than by name.
- **PlayerUtil.getMouseHit:** the raycast filter is built without nil holes, so the character is always excluded.
- `MysLib.Version` now matches the package version.

### Added

- `Signal:DisconnectAll()`, `Signal:Destroy()` (so a signal can be given to a Maid), and `connection.Connected`.
- `Maid.cleanupTask(task)`.
- `StringUtil.RichText.escape(text)` for player-supplied text.
- A spec suite (`lune run tests/run.luau`).
