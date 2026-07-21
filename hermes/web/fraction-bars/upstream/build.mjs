import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const sha256 = (s) => 'sha256-' + createHash('sha256').update(s).digest('base64');

export function buildHtml(manifest, rootDir) {
  const read = (p, kind) => {
    const inline = manifest[kind === 'script' ? 'scriptContents' : 'styleContents'];
    if (inline && p in inline) return inline[p];
    return readFileSync(join(rootDir, p), 'utf8');
  };
  const scriptBody = manifest.scripts.map((p) => read(p, 'script')).join('\n');
  const styleBody = manifest.styles.map((p) => read(p, 'style')).join('\n');
  const scriptHash = sha256(scriptBody);
  const styleHash = sha256(styleBody);
  const csp = [
    "default-src 'none'",
    `script-src '${scriptHash}'`,
    `style-src '${styleHash}'`,
    "img-src data: blob:",
    "connect-src 'none'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'none'",
  ].join('; ');
  const html = `<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<title>Fraction Bars</title>
<style>${styleBody}</style>
</head><body>
${manifest.bodyHtml || ''}
<script>${scriptBody}</script>
</body></html>`;
  return { html, scriptHash, styleHash, csp };
}

// CLI entry
if (process.argv[1] && import.meta.url === `file://${process.argv[1]}`) {
  const root = dirname(fileURLToPath(import.meta.url));
  const manifest = JSON.parse(readFileSync(join(root, 'build.manifest.json'), 'utf8'));
  if (manifest.bodyHtmlFile) manifest.bodyHtml = readFileSync(join(root, manifest.bodyHtmlFile), 'utf8');
  const { html } = buildHtml(manifest, root);
  writeFileSync(join(root, manifest.out), html);
  console.log('Built', manifest.out, '(' + html.length + ' bytes)');
}
