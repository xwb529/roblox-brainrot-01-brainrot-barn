# Brainrot Barn

> **Play it on Roblox:** https://www.roblox.com/games/107118931743775

A funny, original 3D Roblox collecting tycoon in the "Steal a Brainrot" genre, built entirely from primitive Parts and native Roblox UI — no meshes, decals, external assets, monetization, or DataStores. Raise a barn full of peculiar friends, survive the flood schedule, and keep the striped snack bandit away from your cash cows.

Built with a coding agent in recorded sessions for the make.fun **roblox-brainrot-01** bounty.

## The loop

1. Join with **$350** and an automatically assigned barn. Six farmers can own barns at once; extra players can explore while waiting for one to open.
2. Visit the conveyor through the central plaza. New characters arrive every five seconds and walk toward the exit. Hold **E** at a character to buy it.
3. Your purchase follows you. Walk onto one of your barn's **six empty pads** to place it. Placed friends pay Cash automatically every second; their floating labels show name, rarity, and actual income including mutations and rebirths.
4. Hold **E** at an occupied pad to sell its character for **half the original purchase price**. Only the owner can place or sell.
5. Buy stacking **+5 speed** and **+1 carry capacity** upgrades at the shop pads (carry caps at 6, speed allows six upgrades). Upgrades survive rebirth and respawn.
6. **Rebirth** from the HUD, **R**, or the purple altar: Cash resets to $350 and carried/placed friends clear; each rebirth adds a permanent **+50% income** for the session. First rebirth costs $20,000, each next one ×2.5, up to 20 rebirths. Field-guide discoveries and upgrades stay.

## The cast — 14 original friends, 5 rarities

Defined in `src/shared/BrainrotCatalog.luau`:

| Rarity | Friends | Price range | Base income / second |
| --- | --- | --- | --- |
| Common | Sippuccino Sprout, Boogie Spudnik, Peabody Pogo, Toastie Postie | $80–$320 | $3–$11 |
| Rare | Bananafin Bloop, Crumbclaw Courier, Wobble Wafflehop | $650–$1,600 | $24–$58 |
| Epic | Noodleneck Nibbler, Jamjar Jamboree, Shellshot Sputnik | $3,200–$8,000 | $115–$280 |
| Legendary | Pretzel Pandemonium, Dumpling Duckonaut | $16,000–$28,000 | $570–$1,000 |
| Mythic | Mochisaurus Moonbeam, Cosmic Curdleking | $65,000–$95,000 | $2,400–$3,600 |

Wild characters can spawn **Gold (2× income)** or **Diamond (3× income)** with matching material and tint, at the normal purchase price. Mutation chances decrease with rarity. A session field guide tracks discoveries.

## Trouble at the barn

- **The flood:** roughly every three minutes, a ten-second warning banner appears, then a giant translucent wave crosses the plaza and conveyor over nine seconds, washing away unsold lane characters. Players caught in the low plaza return to the welcome mat; barns and the eastern high-ground hill are safe.
- **The striped snack bandit:** every ~75–110 seconds it picks a random unlocked barn with a placed friend, steals one, and runs. Lock your control panel (60 s lock / 60 s cooldown) to foil it, or chase it down and hold **E** to rescue your friend.

## Controls

- **WASD / arrows** move, **Space** jumps, standard Roblox camera.
- **E / controller X / touch prompt:** buy, place, sell, upgrade, lock, rescue.
- **R:** rebirth confirmation. **B:** field guide.

The HUD shows leaderstats Cash, total income, rebirth count/multiplier, barn occupancy, lock/cooldown, carry, speed, upgrade prices, objectives, and wave warnings. All transactions are server-authoritative (ownership, distance, balance, capacity, cooldown, and rate checks). All progress is **in memory only** and ends when you leave the server.

## Repository layout

- `default.project.json` — Rojo mapping, avatar controls, lighting, shared modules in ReplicatedStorage.
- `src/server/init.server.luau` — bootstrap; builds the world and publishes remotes only after handlers are ready.
- `src/server/WorldBuilder.luau` — all primitive scenery, signs, pads, prompts, plot structure.
- `src/server/GameServer.luau` — ownership, purchases, followers, placement, selling, income, upgrades, locks, respawns, rebirths.
- `src/server/ThreatService.luau` — flood schedule/sweep and the bandit's approach, theft, escape, and rescue.
- `src/shared/BrainrotCatalog.luau`, `BuildCharacter.luau`, `Economy.luau` — original catalog, character geometry/labels, economy formulas.
- `src/client/Game.client.luau` — ScreenGui HUD, field guide, alerts, confirmations, ContextActionService shortcuts.
- `main.ts` — the make.fun dossier packager: copies `game.rbxl`, `PLAY.json`, `TOUR.json`, `src/`, and `screenshots/` to the output dir and writes `dossier.json` via the unchanged `vendor/makefun-roblox.ts`.
- `PLAY.json` — the published place link (place id + universe id).
- `screenshots/` — 3–4 captures of the game running in Roblox Studio; the first by name is the cover and matches the experience's first thumbnail.

## Build

Requires Rojo 7.7.1 and Node.js 22+.

```sh
# Build the binary place from src/
rojo build default.project.json --output game.rbxl

# Package the submission dossier
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio and press Play to run it. The place geometry is generated on the server at play time, so Studio's edit view shows the configured services/scripts until Play starts. For multiplayer testing, start a local server with two or more clients and test buying/placing, ownership rejection on another barn, income ticks, half-price selling, rebirth, upgrades across respawn, lock expiry/cooldown, bandit rescue, and a full flood cycle.

## License

MIT License (SPDX-License-Identifier: MIT), Copyright (c) 2026 xwb529 — see `LICENSE`.
