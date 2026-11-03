import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../.config/herdr-app/mods/tmux-prefix/main.js', import.meta.url), 'utf8')
  .replace(/^import .*;\n/gm, '').replace('export default class TmuxPrefix', 'class TmuxPrefix');
const flush = () => new Promise(resolve => setImmediate(resolve));

function setup({ machine = null, cwd = '/repo with spaces', result, delayed = false } = {}) {
  const calls = [], overlays = [], notices = [], order = [];
  let resolve;
  const pending = new Promise(r => { resolve = r; });
  const Class = vm.runInNewContext(`${source}\nTmuxPrefix`, {
    View: class {},
    focused: () => ({ space: 's1', cwd }),
    spaces: () => [{ id: 's1', machine, folder: '/fallback' }],
    props: () => ({ overlay: 'prefix' }),
    closeOverlay: () => order.push('close'),
    openOverlay: spec => { order.push('open'); overlays.push(spec); },
    notify: message => notices.push(message),
    run: (command, args) => { order.push('run'); calls.push([command, { ...args }]); },
    hc: args => {
      calls.push(Array.from(args));
      if (args[0] === 'kill') return Promise.resolve({ code: 0 });
      return delayed ? pending : Promise.resolve(result ?? { code: 0, stdout: '{"address":"t99"}' });
    },
  });
  const view = new Class();
  const cx = { notify() {}, stop_propagation() {} };
  return { view, cx, calls, overlays, notices, order, resolve };
}

test('t opens Atuin Threads after dismissing the prefix', () => {
  const s = setup();
  s.view.key({ key: 't', modifiers: {} }, s.cx);
  assert.deepEqual(s.order, ['close', 'run']);
  assert.deepEqual(s.calls, [['mod.open', { name: 'atuin-threads' }]]);
});

test('Shift+G launches in the current directory and closes prefix before focusing overlay', async () => {
  const s = setup();
  s.view.key({ key: 'g', key_char: 'G', modifiers: { shift: true } }, s.cx);
  await flush();
  assert.deepEqual(s.calls[0], ['run', '--bg', '--json', '--no-notify', '--cwd', '/repo with spaces', '--', 'lazygit']);
  assert.deepEqual(s.order, ['close', 'open']);
  assert.equal(s.overlays[0].layout.children[1].content.terminal, 't99');
  s.view.terminal = 't99';
  await s.view.close();
  assert.deepEqual(s.calls[1], ['kill', 't99']);
});

test('remote launch uses the space machine and folder fallback', async () => {
  const s = setup({ machine: 'remote', cwd: null });
  s.view.lazygit(s.cx);
  await flush();
  assert.deepEqual(s.calls[0], ['run', '--bg', '--json', '--no-notify', '--cwd', '/fallback', '--on', 'remote', '--', 'lazygit']);
});

test('cancelling a pending launch kills the late terminal without opening a popup', async () => {
  const s = setup({ delayed: true });
  s.view.lazygit(s.cx);
  s.view.lazygit(s.cx);
  await s.view.close();
  s.resolve({ code: 0, stdout: '{"address":"t99"}' });
  await flush();
  assert.equal(s.calls.length, 2);
  assert.deepEqual(s.calls[1], ['kill', 't99']);
  assert.equal(s.overlays.length, 0);
});

test('launch errors are surfaced without opening an overlay', async () => {
  const s = setup({ result: { code: 1, stderr: 'lazygit not found' } });
  s.view.lazygit(s.cx);
  await flush();
  assert.match(s.notices[0].body, /lazygit not found/);
  assert.equal(s.overlays.length, 0);
});
