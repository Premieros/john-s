const http = require('node:http');
const os = require('node:os');
const fs = require('node:fs');
const path = require('node:path');
const { execFile } = require('node:child_process');

const HOST = '127.0.0.1';
const PORT = Number(process.env.JOHNS_PRINT_PORT || 17654);
const CONFIG_PATH = path.join(__dirname, 'printer-config.json');
const STATIONS_PATH = path.join(__dirname, 'stations.json');
const MAX_BODY = 256 * 1024;

function originAllowed(origin) {
  if (!origin) return true;
  if (origin === 'https://premieros.github.io') return true;
  try {
    const url = new URL(origin);
    return (url.hostname === '127.0.0.1' || url.hostname === 'localhost') &&
      (url.protocol === 'http:' || url.protocol === 'https:');
  } catch {
    return false;
  }
}

function applyCors(req, res) {
  const origin = req.headers.origin;
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
}

function json(res, status, value) {
  const body = JSON.stringify(value);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store',
  });
  res.end(body);
}

function isValidStationCode(value) {
  const code = String(value || '').trim();
  if (!code || code.length > 64) return false;
  return !/[\u0000-\u001f\u007f/\\]/u.test(code);
}

function normalizeStation(value) {
  if (typeof value === 'string') {
    const code = value.trim();
    return isValidStationCode(code) ? { code, name: code } : null;
  }
  if (!value || typeof value !== 'object') return null;
  const code = String(value.code || '').trim();
  if (!isValidStationCode(code)) return null;
  const name = String(value.name_ar || value.name || value.name_en || code).trim().slice(0, 120) || code;
  return { code, name };
}

function readStations() {
  try {
    const parsed = JSON.parse(fs.readFileSync(STATIONS_PATH, 'utf8'));
    const rows = Array.isArray(parsed) ? parsed : Array.isArray(parsed.stations) ? parsed.stations : [];
    const seen = new Set();
    return rows.flatMap((row) => {
      const station = normalizeStation(row);
      if (!station || seen.has(station.code)) return [];
      seen.add(station.code);
      return [station];
    });
  } catch {
    return [];
  }
}

function saveStations(stations) {
  const clean = [];
  const seen = new Set();
  for (const row of Array.isArray(stations) ? stations : []) {
    const station = normalizeStation(row);
    if (!station || seen.has(station.code)) continue;
    seen.add(station.code);
    clean.push(station);
  }
  fs.writeFileSync(STATIONS_PATH, JSON.stringify({ stations: clean }, null, 2) + '\n', 'utf8');
  return clean;
}

function readRoutes() {
  try {
    const parsed = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
    return parsed.routes && typeof parsed.routes === 'object' ? parsed.routes : {};
  } catch {
    return {};
  }
}

function saveRoutes(routes) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify({ routes }, null, 2) + '\n', 'utf8');
}

function readConfig() {
  return { routes: readRoutes(), stations: readStations() };
}

function syncStations(stations) {
  const clean = saveStations(stations);
  const allowed = new Set(clean.map((s) => s.code));
  const currentRoutes = readRoutes();
  const nextRoutes = {};
  for (const [station, printer] of Object.entries(currentRoutes)) {
    if (allowed.has(station) && printer) nextRoutes[station] = printer;
  }
  saveRoutes(nextRoutes);
  return { stations: clean, routes: nextRoutes };
}

function ensureStation(stationCode) {
  const code = String(stationCode || '').trim();
  if (!isValidStationCode(code)) return false;
  const stations = readStations();
  if (stations.some((s) => s.code === code)) return true;
  saveStations([...stations, { code, name: code }]);
  return true;
}

function ps(script, args = []) {
  return new Promise((resolve, reject) => {
    execFile(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', script, ...args],
      { windowsHide: true },
      (err, stdout, stderr) => {
        if (err) return reject(new Error((stderr || err.message || '').trim()));
        resolve(stdout);
      }
    );
  });
}

async function listPrinters() {
  const out = await ps("Get-Printer | Select-Object -ExpandProperty Name | ConvertTo-Json -Compress");
  const parsed = JSON.parse(String(out || '[]').trim() || '[]');
  if (Array.isArray(parsed)) return parsed.map(String).sort();
  return parsed ? [String(parsed)] : [];
}

async function printText(printerName, text) {
  const printers = await listPrinters();
  if (!printers.includes(printerName)) throw new Error('PRINTER_NOT_INSTALLED');
  const tmp = path.join(os.tmpdir(), `johns-ticket-${Date.now()}-${Math.random().toString(16).slice(2)}.txt`);
  fs.writeFileSync(tmp, text, 'utf8');
  try {
    const script = "$p=$args[0];$f=$args[1];Get-Content -LiteralPath $f -Raw -Encoding UTF8 | Out-Printer -Name $p";
    await ps(script, [printerName, tmp]);
  } finally {
    try { fs.unlinkSync(tmp); } catch {}
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY) {
        reject(new Error('PAYLOAD_TOO_LARGE'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'));
      } catch {
        reject(new Error('INVALID_JSON'));
      }
    });
    req.on('error', reject);
  });
}

function html(res, body) {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(body);
}

function configPage() {
  return `<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><title>Johns Print Service</title>
<style>
body{font-family:Segoe UI,Tahoma,sans-serif;max-width:820px;margin:32px auto;padding:0 18px;background:#f6f7f9;color:#171717}
h1{margin-bottom:4px}.card{background:#fff;border:1px solid #ddd;border-radius:14px;padding:18px;margin:16px 0}
.station{border-bottom:1px solid #eee;padding:10px 0}.station:last-child{border-bottom:0}
label{display:block;font-weight:700;margin:0 0 5px}select,input,button{font:inherit;padding:10px;border-radius:9px;border:1px solid #bbb}
select{width:100%}button{cursor:pointer;background:#111;color:#fff;border:0;margin:8px 4px}.danger{background:#8b1d1d}
.ok{color:#087a37}.muted{color:#666;font-size:13px}.empty{padding:18px;text-align:center;color:#777}.actions{display:flex;flex-wrap:wrap;gap:5px}
</style>
<body>
<h1>Johns Print Service</h1>
<div class="muted">إعداد الطابعات لهذا الجهاز فقط — أسماء الطابعات لا تُرسل إلى قاعدة البيانات.</div>
<div class="card"><div id="status">جاري قراءة الطابعات والمحطات…</div><div id="stations"></div><div class="actions"><button onclick="saveRoutes()">حفظ ربط الطابعات</button><button onclick="addStation()">إضافة محطة يدويًا</button><button onclick="reload()">تحديث</button></div></div>
<div class="card muted">المحطات لم تعد ثابتة داخل البرنامج. يتم حفظ قائمة المحطات في <b>stations.json</b>، وأي محطة جديدة تصل من شاشة البيع تُضاف تلقائيًا. عند مزامنة قائمة جديدة تُحذف المحطات القديمة من القائمة.</div>
<script>
let printers=[],config={routes:{},stations:[]};
function esc(s){return String(s).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));}
async function reload(){const [p,c]=await Promise.all([fetch('/printers').then(r=>r.json()),fetch('/config').then(r=>r.json())]);printers=p.printers||[];config=c||{routes:{},stations:[]};render();}
function render(){document.getElementById('status').innerHTML='<span class="ok">الخدمة متصلة</span> — '+printers.length+' طابعة — '+(config.stations||[]).length+' محطة';const rows=(config.stations||[]);document.getElementById('stations').innerHTML=rows.length?rows.map(s=>{const code=typeof s==='string'?s:s.code;const name=typeof s==='string'?s:(s.name||s.code);const opts=['<option value="">بدون طابعة / استخدم fallback</option>',...printers.map(p=>'<option value="'+esc(p)+'" '+((config.routes||{})[code]===p?'selected':'')+'>'+esc(p)+'</option>')].join('');return '<div class="station" data-code="'+esc(code)+'"><label>'+esc(name)+' <span class="muted">('+esc(code)+')</span></label><select>'+opts+'</select><button class="danger" onclick="removeStation('+JSON.stringify(code).replace(/"/g,'&quot;')+')">حذف المحطة من هذا الجهاز</button></div>';}).join(''):'<div class="empty">لا توجد محطات محفوظة. أعد فتح شاشة البيع أو أضف محطة يدويًا.</div>';}
async function saveRoutes(){const routes={};document.querySelectorAll('.station').forEach(row=>{const v=row.querySelector('select').value;if(v)routes[row.dataset.code]=v;});const r=await fetch('/config',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({routes})});config=await r.json();render();alert('تم الحفظ');}
async function setStations(stations){const r=await fetch('/stations',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({stations})});const data=await r.json();if(!r.ok)return alert(data.error||'تعذر تحديث المحطات');config=data;render();}
async function addStation(){const code=prompt('اكتب كود/اسم المحطة كما يظهر في النظام');if(!code||!code.trim())return;await setStations([...(config.stations||[]),{code:code.trim(),name:code.trim()}]);}
async function removeStation(code){if(!confirm('حذف '+code+' من قائمة هذا الجهاز؟'))return;await setStations((config.stations||[]).filter(s=>(typeof s==='string'?s:s.code)!==code));}
reload().catch(e=>document.getElementById('status').textContent='خطأ: '+e.message);
</script></body></html>`;
}

const server = http.createServer(async (req, res) => {
  const origin = req.headers.origin;
  if (!originAllowed(origin)) {
    res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
    return res.end('Origin not allowed');
  }
  applyCors(req, res);
  if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
  try {
    const url = new URL(req.url, `http://${HOST}:${PORT}`);
    if (req.method === 'GET' && url.pathname === '/') return html(res, configPage());
    if (req.method === 'GET' && url.pathname === '/health') return json(res, 200, { ok: true, service: 'johns-print-agent', version: 2 });
    if (req.method === 'GET' && url.pathname === '/printers') return json(res, 200, { printers: await listPrinters() });
    if (req.method === 'GET' && url.pathname === '/config') return json(res, 200, readConfig());
    if (req.method === 'GET' && url.pathname === '/stations') return json(res, 200, { stations: readStations() });
    if (req.method === 'POST' && url.pathname === '/stations') {
      const body = await readBody(req);
      if (!Array.isArray(body.stations) || body.stations.length > 100) return json(res, 400, { success: false, error: 'INVALID_STATIONS' });
      const synced = syncStations(body.stations);
      return json(res, 200, { success: true, ...synced });
    }
    if (req.method === 'POST' && url.pathname === '/config') {
      const body = await readBody(req);
      const printers = await listPrinters();
      const stations = new Set(readStations().map((s) => s.code));
      const routes = {};
      for (const [station, printer] of Object.entries(body.routes || {})) {
        if (!isValidStationCode(station) || !stations.has(station)) return json(res, 400, { success: false, error: 'INVALID_STATION', station });
        if (printer && !printers.includes(String(printer))) return json(res, 400, { success: false, error: 'PRINTER_NOT_INSTALLED', station });
        if (printer) routes[station] = String(printer);
      }
      saveRoutes(routes);
      return json(res, 200, { routes, stations: readStations() });
    }
    if (req.method === 'POST' && url.pathname === '/print') {
      const body = await readBody(req);
      const station = String(body.station || '').trim();
      const text = String(body.text || '');
      if (!isValidStationCode(station)) return json(res, 400, { success: false, error: 'INVALID_STATION' });
      if (!text || text.length > 200000) return json(res, 400, { success: false, error: 'INVALID_TEXT' });
      ensureStation(station);
      const config = readConfig();
      const printer = body.printer ? String(body.printer) : config.routes[station];
      if (!printer) return json(res, 409, { success: false, error: 'STATION_NOT_CONFIGURED', station, discovered: true });
      await printText(printer, text);
      return json(res, 200, { success: true, station, printer });
    }
    return json(res, 404, { error: 'NOT_FOUND' });
  } catch (err) {
    return json(res, 500, { success: false, error: err instanceof Error ? err.message : 'PRINT_AGENT_ERROR' });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Johns Print Service v2: http://${HOST}:${PORT}`);
  console.log(`Printer setup: http://${HOST}:${PORT}/`);
});
