// ——— Universal SCON-From-JSON Converter ———

// ——— SCON-escaping functions ———
function sconChar(ch) {
  const cp = ch.codePointAt(0);
  if (cp >= 32 && cp <= 127) {
    if (ch === '\\') return '\\\\';
    if (ch === '"') return '\\"';
    return ch;
  }
  if (cp <= 0xFF) {
    if (ch === '\n') return '\\n';
    if (ch === '\r') return '\\r';
    if (ch === '\t') return '\\t';
    return '\\x' + cp.toString(16).padStart(2, '0');
  }
  if (cp <= 0xFFFF) {
    return '\\u' + cp.toString(16).padStart(4, '0');
  }
  return '\\U' + cp.toString(16).padStart(8, '0');
}

function sconString(s) {
  let out = '';
  for (const ch of s) out += sconChar(ch);
  return `"${out}"`;
}

function sconFromJson(data) {
  if (data === null) return 'undef';
  if (Array.isArray(data)) return '[' + data.map(sconFromJson).join(', ') + ']';
  if (typeof data === 'object') {
    const items = [];
    for (const [k, v] of Object.entries(data)) {
      items.push(`[${sconString(k)}, ${sconFromJson(v)}]`);
    }
    return '[' + items.join(', ') + ']';
  }
  if (typeof data === 'string') return sconString(data);
  if (typeof data === 'boolean') return data ? 'true' : 'false';
  return String(data);
}

function argv(i) {
  return (typeof scriptArgs !== 'undefined') ? scriptArgs[i] : process.argv[1+i];
}

function argc() {
  return (typeof scriptArgs !== 'undefined') ? scriptArgs.length : process.argv.length - 1;
}

function exit(code) {
  if (typeof scriptArgs != 'undefined') {
    std.exit(code);
  } else {
    process.exit(code);
  }
  throw new Error("unreached");
}

async function readStdin() {
  if (typeof scriptArgs !== 'undefined') {
    let lines = [];
    for (;;) {
        let line = std.in.getline();
        if (line === null) break;
        lines.push(line);
    }
    return lines.join("\n");
  } else {
    const { readFileSync } = await import('fs');
    return readFileSync(0, 'utf-8');
  }
}

async function main() {
  let fmt = '{scon}';
  for (let i = 1; i<argc(); ++i) {
    const a = argv(i);
    if (a.startsWith('--fmt=')) fmt = a.slice(6);
    else if (a === '--fmt' && args[i + 1]) fmt = args[++i];
    else {
      console.log("invalid argument");
      exit(1);
    }
  }

  try {
  const text = await readStdin();
  const json = JSON.parse(text);
  const scon = sconFromJson(json);
  console.log(fmt.replace('{scon}', scon));
  } catch (e) {
    console.log(e);
    exit(1);
  }
}

if (argc() > 1 && argv(0).endsWith("json2scon.js")) {
  await main();
}

export { sconFromJson }