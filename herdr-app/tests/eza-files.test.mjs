import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../.config/herdr-app/mods/eza-files/main.js', import.meta.url), 'utf8')
  .replace(/^import .*;\n/gm, '').replace('export default class Files', 'class Files');

// Runs the mod's real shell script, with PATH limited to `path`.
function load(path) {
  return vm.runInNewContext(`${source}\n({ directory, parseEza })`, {
    View: class {},
    window: () => ({ platform: 'macos' }),
    exec: async (cmd, args) => {
      const r = spawnSync(cmd, args, { encoding: 'utf8', env: { PATH: path } });
      return { code: r.status, stdout: r.stdout, stderr: r.stderr };
    },
  });
}

// The folder holding a working eza: EZA_DIR, else PATH's (a version manager shim must run).
function eza() {
  if (process.env.EZA_DIR) return process.env.EZA_DIR;
  const r = spawnSync('sh', ['-c', 'command -v eza && eza --version'], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout.split('\n')[0].replace(/\/eza$/, '') : null;
}

function fixture() {
  const dir = mkdtempSync(join(tmpdir(), 'eza-files-'));
  mkdirSync(join(dir, 'sub'));
  mkdirSync(join(dir, '.git'));
  for (const name of ['a.js', 'Cargo.toml', 'sp ace.md', '.hidden']) writeFileSync(join(dir, name), '');
  chmodSync(join(dir, 'a.js'), 0o755);
  symlinkSync('sub', join(dir, 'link'));
  return dir;
}

const byName = entries => Object.fromEntries(entries.map(e => [e.name, e]));
const SYSTEM = '/usr/bin:/bin';

test('lists names and kinds like the shipped mod, without .git', async () => {
  const entries = await load(SYSTEM).directory(fixture(), null);
  assert.deepEqual(JSON.parse(JSON.stringify(entries.map(e => [e.name, e.dir]).sort())), [
    ['.hidden', false], ['Cargo.toml', false], ['a.js', false], ['link', false], ['sp ace.md', false], ['sub', true],
  ]);
});

test('falls back to SVG icons when eza is missing', async () => {
  const entries = await load(SYSTEM).directory(fixture(), null);
  assert.ok(entries.every(e => e.eza === null));
});

test('rejects a missing folder', async () => {
  await assert.rejects(load(SYSTEM).directory('/no/such/folder', null));
});

test('takes icons and colors from eza for every entry', { skip: !eza() && 'eza not on PATH' }, async () => {
  const entries = byName(await load(`${eza()}:${SYSTEM}`).directory(fixture(), null));
  for (const name of ['.hidden', 'Cargo.toml', 'a.js', 'link', 'sp ace.md', 'sub']) {
    assert.ok(entries[name].eza, `${name} has an eza icon`);
    assert.equal(Array.from(entries[name].eza.icon).length, 1);
  }
  assert.notEqual(entries['a.js'].eza.icon, entries['Cargo.toml'].eza.icon);
});

test('parses SGR colors, bold, symlinks and quoted names', () => {
  const { parseEza } = load(SYSTEM);
  const text = [
    '\x1b[38;2;243;139;168m\ue74e \x1b[1ma.js\x1b[0m',
    '\x1b[34m\uf115 sub\x1b[0m',
    '\x1b[38;5;214m\ue5ff link\x1b[0m \x1b[1;90m->\x1b[0m \x1b[34msub\x1b[0m',
    "\uf48a 'sp ace.md'",
    '\uf15b .hidden',
    '\uf15b unknown',
  ].join('\n');
  const icons = parseEza(text, new Set(['a.js', 'sub', 'link', 'sp ace.md', '.hidden']));
  assert.deepEqual({ ...icons.get('a.js') }, { icon: '\ue74e', color: '#f38ba8', nameColor: '#f38ba8', bold: true });
  assert.deepEqual({ ...icons.get('sub') }, { icon: '\uf115', color: 'ansi4', nameColor: 'ansi4', bold: false });
  assert.equal(icons.get('link').color, '#ffaf00');
  assert.equal(icons.get('sp ace.md').icon, '\uf48a');
  assert.equal(icons.get('.hidden').color, null);
  assert.equal(icons.has('unknown'), false);
});
