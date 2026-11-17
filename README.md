# Brainrot Barn

A funny, original 3D Roblox collecting tycoon built entirely from primitive Parts and native Roblox UI. Raise a barn full of peculiar friends, survive the Silly Express's flood schedule, and keep the striped snack bandit away from your cash cows. No meshes, decals, external assets, monetization, or DataStores.

## The loop

1. Join with **$350** and an automatically assigned barn. Six farmers can own barns at once; extra players can explore while waiting for one to open. Your barn has a mint outline and a numbered ownership sign.
2. Visit the conveyor through the central plaza. New characters arrive every five seconds and walk toward the exit. Hold **E** at a character to buy it. The first arrivals and regular affordable spawns make it possible to start small.
3. Your purchase follows you. Walk onto one of your barn's **six empty pads** to place it, or use the pad's prompt. Placed friends pay Cash automatically every second. Their floating labels show name, rarity, and actual income including mutations and rebirths.
4. Hold **E** at one of your occupied pads to sell its character for **half the original purchase price**. Only the owner can place or sell. Purchased followers are refunded if you die before placing them.
5. Buy stacking **+5 speed** and **+1 carry capacity** upgrades at the two shop pads beside the welcome spawn. Carry starts at one and caps at six; speed starts at 18 and allows six upgrades. Current prices are on the HUD. Upgrades survive rebirth and avatar respawn.
6. Rebirth from the HUD, **R**, or the purple altar's prompt. Review the confirmation before committing. The first rebirth costs **$20,000**; each subsequent price multiplies by 2.5. Cash resets to $350 and all carried/placed friends clear; each rebirth adds a permanent **+50% income** for the current session. Up to 20 rebirths; discovered field-guide entries and upgrades stay.

## Friends worth farming

`src/shared/BrainrotCatalog.luau` contains 14 original characters across five rarities:

| Rarity | Friends | Price range | Base income / second |
| --- | --- | --- | --- |
| Common | Sippuccino Sprout, Boogie Spudnik, Peabody Pogo, Toastie Postie | $80–$320 | $3–$11 |
| Rare | Bananafin Bloop, Crumbclaw Courier, Wobble Wafflehop | $650–$1,600 | $24–$58 |
| Epic | Noodleneck Nibbler, Jamjar Jamboree, Shellshot Sputnik | $3,200–$8,000 | $115–$280 |
| Legendary | Pretzel Pandemonium, Dumpling Duckonaut | $16,000–$28,000 | $570–$1,000 |
| Mythic | Mochisaurus Moonbeam, Cosmic Curdleking | $65,000–$95,000 | $2,400–$3,600 |

The catalog-driven character builder gives each creature a distinct body, eyes, shoes, and signature accessory. Wild characters can spawn **Gold (2× income)** or **Diamond (3× income)** with matching material and tint, at the normal purchase price. Mutation chances decrease with rarity. The field guide shows the complete catalog and tracks discoveries for the session.

## Trouble at the barn

**Tsunami:** roughly every three minutes, a blue banner gives a ten-second warning. A giant translucent wall with foamy crests crosses the plaza and conveyor over nine seconds, washing away unsold lane characters as it passes. Players caught in the low plaza return to the welcome mat; purchased followers stay safe. All barns and the stepped eastern high-ground hill are outside the danger zone. New conveyor arrivals pause during the sweep.

**The striped snack bandit:** first checks for a target after 65 seconds, then every 75–110 seconds. It walks to a random unlocked barn that has a placed friend, takes one, and runs away with it. Lock your control panel before it reaches the pads to foil the attempt. If it steals a friend, the owner can chase it and hold **E** to rescue the character back to a free pad before it escapes. A lock lasts 60 seconds, followed by 60 seconds of cooldown. Unlocking early does not bypass the original cooldown. Locks protect against the bot; the visual barrier lets farmers walk freely.

## Controls

- **WASD / arrow keys:** standard Roblox movement; **Space:** jump.
- **Mouse / thumbstick / touch:** standard Roblox camera and movement controls.
- **E / controller X / touch prompt:** buy, place, sell, upgrade, lock, claim, or rescue when nearby.
- **R / Rebirth HUD button:** open rebirth confirmation; press R again or choose Keep Farming to close.
- **B / Field Guide HUD button:** toggle the collection guide.

The HUD shows leaderstats Cash, total income, rebirth count/multiplier, barn occupancy, lock/cooldown, carry capacity, speed, upgrade prices, objectives, and wave warnings. The 3D map has six open barns, a conveyor market, simple trees, portals, a stepped hill, and SurfaceGui signs.

## Repository and build

- `default.project.json`: Rojo mapping, standard 3D avatar controls, lighting, and shared modules in ReplicatedStorage.
- `src/server/init.server.luau`: bootstrap; constructs the world and publishes RemoteEvents/RemoteFunction only after handlers are ready.
- `src/server/WorldBuilder.luau`: all primitive scenery, signs, pads, prompts, and plot structure.
- `src/server/GameServer.luau`: ownership, purchases, followers, placement, selling, income, upgrades, locks, respawns, and rebirths.
- `src/server/ThreatService.luau`: tsunami schedule/sweep and the thief's approach, theft, escape, and rescue.
- `src/shared/BrainrotCatalog.luau`, `BuildCharacter.luau`, `Economy.luau`: original catalog, character geometry/labels, and economy formulas.
- `src/client/Game.client.luau`: responsive ScreenGui, field guide, alerts, confirmation, and ContextActionService shortcuts.
- `main.ts`: original dossier workflow plus copying `TOUR.json` and logging each copied item; uses the unchanged `vendor/` library.

All transactions are server-authoritative, with ownership, distance, balance, capacity, cooldown, and rate checks. The client can request a rebirth or a state snapshot; it cannot submit prices, balances, spawn rolls, or income. All progress is **in memory** and ends when you leave the server.

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio and use Play to run the procedurally built game. For multiplayer testing, start a local server with two or more clients. Test buying and placing, ownership rejection on another barn, income ticks, half-price selling, rebirth confirmation, upgrades across respawn, lock expiration/cooldown, thief rescue, and a full 180-second wave cycle.

The place geometry is generated on the server at play time. Studio's edit view will show the configured services/scripts until Play starts. `PLAY.json`, `TOUR.json`, and `screenshots/` retain their supplied starter contents; the screenshots/tour are historical starter material, not captures of Brainrot Barn. No published place ID has been invented. Publishing and refreshing those submission materials remain separate from building this game.
