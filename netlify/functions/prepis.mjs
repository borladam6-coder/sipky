// Přepis hlasu pro Šipky: nahrávka z telefonu → Whisper (Groq) → text.
// Klíč se nastavuje na Netlify jako proměnná prostředí GROQ_API_KEY (nikdy ne v kódu).
const MODEL = 'whisper-large-v3';
const PROMPT = 'Šipky. Triple dvacet, dvacet, double pět. Trojka devatenáct, dvojka šestnáct. Bull, malý bull, pětadvacet. Mimo, vedle, nic. Zpět. Zapsat.';

export default async (req) => {
  const key = process.env.GROQ_API_KEY;
  if (req.method === 'GET') return Response.json({ ok: true, key: !!key });
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  if (req.headers.get('x-sipky') !== '1') return Response.json({ error: 'forbidden' }, { status: 403 });
  if (!key) return Response.json({ error: 'no_key' }, { status: 503 });

  const type = (req.headers.get('content-type') || 'audio/mp4').split(';')[0];
  const buf = await req.arrayBuffer();
  if (!buf.byteLength) return Response.json({ error: 'empty' }, { status: 400 });
  if (buf.byteLength > 4 * 1024 * 1024) return Response.json({ error: 'too_large' }, { status: 413 });
  const ext = type.includes('webm') ? 'webm' : type.includes('ogg') ? 'ogg' : type.includes('wav') ? 'wav' : type.includes('mpeg') ? 'mp3' : 'm4a';

  const fd = new FormData();
  fd.append('file', new Blob([buf], { type }), 'nahravka.' + ext);
  fd.append('model', MODEL);
  fd.append('language', 'cs');
  fd.append('prompt', PROMPT);
  fd.append('temperature', '0');
  fd.append('response_format', 'json');

  try {
    const r = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
      method: 'POST', headers: { Authorization: 'Bearer ' + key }, body: fd
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) return Response.json({ error: 'upstream', status: r.status, detail: (j.error && j.error.message || '').slice(0, 160) }, { status: 502 });
    return Response.json({ text: j.text || '' });
  } catch (e) {
    return Response.json({ error: 'upstream', detail: String(e && e.message || e).slice(0, 160) }, { status: 502 });
  }
};

export const config = { path: '/api/prepis' };
