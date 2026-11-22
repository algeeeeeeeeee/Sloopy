import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const errors = [];
const root = process.cwd();

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
  } catch (error) {
    errors.push(`${file}: ${error.message}`);
    return null;
  }
}

function check(condition, message) {
  if (condition) {
    console.log(`[OK]   ${message}`);
  } else {
    console.log(`[FAIL] ${message}`);
    errors.push(message);
  }
}

console.log('=== SLOOPY PROJECT CHECK ===');

const pkg = readJson('package.json');
const lock = readJson('package-lock.json');
const cap = readJson('capacitor.config.json');
const manifest = readJson('www/manifest.webmanifest');
const blankHomeScreenLabel = '\u200B';

check(
  Number(process.versions.node.split('.')[0]) >= 22,
  `Node.js ${process.versions.node} (minimum 22)`
);

if (pkg && lock) {
  check(lock.lockfileVersion === 3, 'Lockfile version 3');

  for (const name of [
    '@capacitor/core',
    '@capacitor/ios',
    '@capacitor/cli'
  ]) {
    const version =
      pkg.dependencies?.[name] ??
      pkg.devDependencies?.[name];

    const lockVersion =
      lock.packages?.[`node_modules/${name}`]?.version;

    check(
      Boolean(version && version === lockVersion),
      `${name} version matches package-lock.json`
    );
  }
}

if (cap) {
  check(
    Boolean(cap.appId && cap.appName),
    'Capacitor app identity exists'
  );
  check(
    cap.appName === blankHomeScreenLabel,
    'Capacitor Home Screen label is visually blank'
  );

  check(
    fs.existsSync(path.join(root, cap.webDir || 'www', 'index.html')),
    'Capacitor webDir contains index.html'
  );
}

const nativeProjectPath = path.join(root, 'Native/project.yml');
if (fs.existsSync(nativeProjectPath)) {
  const nativeProject = fs.readFileSync(nativeProjectPath, 'utf8');
  const displayName = nativeProject.match(
    /^\s*INFOPLIST_KEY_CFBundleDisplayName:\s*"([^"]*)"\s*$/m
  )?.[1];
  check(
    displayName === blankHomeScreenLabel,
    'Native iOS Home Screen label is visually blank'
  );
}

const htmlPath = path.join(root, 'www/index.html');
if (fs.existsSync(htmlPath)) {
  const html = fs.readFileSync(htmlPath, 'utf8');
  const tags = [...html.matchAll(
    /<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi
  )];
  const inline = tags.filter(([, attrs]) => !/\bsrc\s*=/i.test(attrs));

  check(inline.length > 0, 'Inline application script exists');

  const appleTitleTag = html.match(
    /<meta\b(?=[^>]*\bname=["']apple-mobile-web-app-title["'])[^>]*>/i
  )?.[0] ?? '';
  const appleTitle = appleTitleTag.match(/\bcontent=["']([^"']*)["']/i)?.[1]
    ?.replace(/&#8203;|&#x200b;/gi, blankHomeScreenLabel);
  check(
    appleTitle === blankHomeScreenLabel,
    'iOS Home Screen label is visually blank'
  );

  inline.forEach(([, , code], index) => {
    try {
      new vm.Script(code, { filename: `index.html script ${index + 1}` });
      check(true, `Inline JavaScript ${index + 1} syntax`);
    } catch (error) {
      check(false, `Inline JavaScript: ${error.message}`);
    }
  });
} else {
  check(false, 'www/index.html exists');
}

const swPath = path.join(root, 'www/sw.js');
if (fs.existsSync(swPath)) {
  const sw = fs.readFileSync(swPath, 'utf8');

  try {
    new vm.Script(sw, { filename: 'www/sw.js' });
    check(true, 'Service Worker JavaScript syntax');
  } catch (error) {
    check(false, `Service Worker syntax: ${error.message}`);
  }

  const match = sw.match(
    /const\s+APP_SHELL\s*=\s*(\[[\s\S]*?\]);/
  );

  check(Boolean(match), 'Service Worker APP_SHELL declaration');

  if (match) {
    const entries = [...match[1].matchAll(/['"]([^'"]+)['"]/g)]
      .map(item => item[1]);

    for (const entry of entries) {
      const relative = entry.replace(/^\.\//, '');
      const target = path.resolve(
        root,
        'www',
        relative || '.'
      );
      const file = entry.endsWith('/')
        ? path.join(target, 'index.html')
        : target;

      check(
        file.startsWith(path.resolve(root, 'www') + path.sep) &&
        fs.existsSync(file),
        `APP_SHELL file exists: ${entry}`
      );
    }
  }
} else {
  check(false, 'www/sw.js exists');
}

if (manifest) {
  check(
    manifest.name === blankHomeScreenLabel,
    'Manifest name is visually blank'
  );
  check(
    manifest.short_name === blankHomeScreenLabel,
    'Manifest short_name is visually blank'
  );
  check(Array.isArray(manifest.icons), 'Manifest icons list exists');

  for (const icon of manifest.icons ?? []) {
    const file = path.resolve(root, 'www', icon.src);

    check(
      file.startsWith(path.resolve(root, 'www') + path.sep) &&
      fs.existsSync(file),
      `Manifest icon exists: ${icon.src}`
    );

    if (fs.existsSync(file)) {
      const buffer = fs.readFileSync(file);
      const validPng =
        buffer.length >= 24 &&
        buffer.subarray(0, 8).equals(
          Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
        );

      check(validPng, `Valid PNG: ${icon.src}`);

      if (validPng) {
        const width = buffer.readUInt32BE(16);
        const height = buffer.readUInt32BE(20);
        const expected = icon.sizes?.split('x').map(Number);

        check(
          !expected || (width === expected[0] && height === expected[1]),
          `PNG dimensions: ${icon.src} (${width}x${height})`
        );
      }
    }
  }
}

console.log('\n=== RESULT ===');

if (errors.length) {
  console.error(`${errors.length} check(s) failed.`);
  process.exit(1);
}

console.log('All checks passed.');
