const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

for (const file of ['RIFD.html', 'site/index.html', 'index.html']) {
  const content = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
  if (!content.toLowerCase().startsWith('<!doctype html>')) throw new Error(file + ': missing DOCTYPE');
  if (!content.includes('رِفد') || !content.includes('FZ_HOOKS')) throw new Error(file + ': missing application code');
  const scripts = [...content.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)];
  if (scripts.length < 3) throw new Error(file + ': missing script blocks');
  for (const [i, block] of scripts.entries()) new vm.Script(block[1], { filename: file + '#script-' + (i + 1) });
  console.log(file + ': ' + scripts.length + ' scripts parsed');
}
console.log('RIFD syntax smoke checks passed; browser/E2E verification is still required.');
