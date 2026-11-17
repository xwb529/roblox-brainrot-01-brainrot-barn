// Node 22+ dossier packager. Build the place with Rojo before running this file.
import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';
// Exclude hidden entries at every depth, preserving the dossier naming contract.
const notDotted = (path: string): boolean => !basename(path).startsWith('.');
mkdirSync(out, { recursive: true });
for (const name of ['game.rbxl', 'PLAY.json', 'TOUR.json']) {
  copyFileSync(join(here, name), join(out, name));
  console.log(`Copied ${name} -> ${join(out, name)}`);
}
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
console.log(`Copied src/ -> ${join(out, 'src')}`);
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
  console.log(`Copied screenshots/ -> ${join(out, 'screenshots')}`);
}
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
console.log(`Wrote ${join(out, 'dossier.json')}`);
