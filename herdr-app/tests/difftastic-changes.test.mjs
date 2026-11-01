import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../.config/herdr-app/mods/difftastic-changes/main.js', import.meta.url), 'utf8')
  .replace(/^import .*;\n/gm, '').replace('export default class Changes', 'class Changes');
function load(root, execute) {
  return vm.runInNewContext(`${source}\n({ Changes, diffRows, key })`, {
    View: class {}, spaces: () => [{ active: true, folder: root, machine: null }],
    panes: () => [], focused: () => ({}), settings: () => ({ dark: true }),
    readTextFile: async path => readFileSync(path, 'utf8'),
    exec: execute ?? (async (cmd, args, options) => {
      const r = spawnSync(cmd, args, { cwd: options.cwd, encoding: 'utf8' });
      return { code: r.status, stdout: r.stdout, stderr: r.stderr };
    }),
  });
}
const plain = panel => panel.rows.map(spans => spans.map(s => s.text).join('')).join('\n');

test('preserves whitespace, ANSI colors and emphasis across rows, with bounded previews', () => {
  const { Changes } = load('/tmp');
  const p = new Changes();
  p.setLines(['\x1b[91;1m  old', 'value\x1b[0m plain']);
  assert.equal(plain(p), '  old\nvalue plain');
  assert.equal(p.rows[1][0].fg, 'ansi9');
  assert.equal(p.rows[1][0].bold, true);
  assert.equal(p.rows[1][1].fg, null);
  p.setLines(['x'.repeat(5000)]);
  assert.equal(p.rows[0][0].text.length, 4000);
  assert.match(plain(p), /diff truncated/);
  p.setLines(Array(1501).fill('x'));
  assert.equal(p.rows.length, 1501);
});

test('real configured difftastic handles tracked, staged, new, deleted and binary files', async () => {
  const root = mkdtempSync(join(tmpdir(), 'difftastic-changes-'));
  const git = (...args) => {
    const r = spawnSync('git', args, { cwd: root, encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
  };
  try {
    git('init', '-q'); git('config', 'diff.external', 'difft');
    git('config', 'user.name', 'Test'); git('config', 'user.email', 'test@example.invalid');
    const path = 'sp ace [x].js';
    writeFileSync(join(root, path), 'const value = 1;\n');
    git('add', '--', path); git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'fixture');
    const { Changes, key } = load(root);
    const p = new Changes(); p.root = root; p.on = null; p.hasHead = true;
    const show = async (path, fresh = false) => {
      p.open = path; p.files = [{ path, fresh, status: fresh ? 'A' : 'M' }];
      await p.load(path, key());
      assert.ok(p.rows.length);
      assert.doesNotMatch(plain(p), /\x1b/);
      return plain(p);
    };
    writeFileSync(join(root, path), 'const value = 2;\n');
    assert.match(await show(path), /JavaScript/);
    assert.ok(p.rows.flat().some(s => s.fg));
    git('add', '--', path);
    assert.match(await show(path), /2/);
    writeFileSync(join(root, 'new.js'), 'const added = true;\n');
    assert.match(await show('new.js', true), /added/);
    assert.equal(p.files[0].add, 1);
    rmSync(join(root, path));
    assert.match(await show(path), /value/);
    writeFileSync(join(root, 'binary.bin'), Buffer.from([0, 1, 2]));
    assert.match(await show('binary.bin', true), /binary/i);
    p.hasHead = false;
    assert.match(await show('new.js', true), /added/);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('routes remote execution, reports tool errors and ignores stale file results', async () => {
  let captured;
  const { Changes, key } = load('/repo', async (cmd, args, opts) => {
    captured = { cmd, args, opts };
    return { code: 0, stdout: 'new output', stderr: '' };
  });
  const p = new Changes(); p.root = '/repo'; p.on = 'remote'; p.hasHead = true;
  p.files = [{ path: 'a.js' }]; p.open = 'b.js'; p.setLines(['keep']);
  await p.load('a.js', key());
  assert.equal(captured.opts.on, 'remote');
  assert.ok(captured.args.includes('--ext-diff'));
  assert.equal(plain(p), 'keep');
  const failed = load('/repo', async () => ({ code: 128, stdout: '', stderr: 'difft missing' }));
  const q = new failed.Changes(); Object.assign(q, { root: '/repo', files: [{ path: 'a.js' }], hasHead: true });
  await assert.rejects(q.load('a.js', failed.key()), /difft missing/);
});
