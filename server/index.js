// Local AI relay for Code-Buddy.
//
// Reads OPENAI_API_KEY from .env (never ships to the browser) and streams
// the OpenAI SSE response straight back to the Flutter app.

import 'dotenv/config';
import cors from 'cors';
import express from 'express';

const app = express();
app.use(express.json({ limit: '256kb' }));
app.use(
  cors({
    // Allow any origin during local dev. The server only listens on
    // localhost by default, so this is safe.
    origin: true,
    credentials: false,
  }),
);

const PORT = Number(process.env.PORT) || 3001;
const API_KEY = process.env.OPENAI_API_KEY;
// Any OpenAI-compatible chat-completions endpoint works (OpenAI, Groq,
// OpenRouter, Together, Ollama, etc). The default is OpenAI.
const API_BASE = (process.env.OPENAI_API_BASE || 'https://api.openai.com/v1').replace(/\/$/, '');
// Server picks the actual model. The client only signals "use the real
// backend" vs "mock"; whatever model the user configures here is what runs.
const MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';
const SYSTEM_PROMPT =
  'You are a beginner-friendly coding tutor. Explain errors clearly and teach concepts in simple language. Prefer short paragraphs and fenced code blocks.';

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    hasKey: Boolean(API_KEY),
    apiBase: API_BASE,
    model: MODEL,
  });
});

app.post('/api/ai/debug', async (req, res) => {
  if (!API_KEY) {
    res.status(500).json({
      error:
        'Server is missing OPENAI_API_KEY. Copy server/.env.example to server/.env and add a key, then restart.',
    });
    return;
  }

  const { code, language } = req.body ?? {};
  if (typeof code !== 'string' || code.trim().length === 0) {
    res.status(400).json({ error: 'Field "code" is required.' });
    return;
  }
  if (typeof language !== 'string' || language.trim().length === 0) {
    res.status(400).json({ error: 'Field "language" is required.' });
    return;
  }

  let upstream;
  try {
    upstream = await fetch(`${API_BASE}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.25,
        stream: true,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: `Analyze this ${language} code. Explain the bug, fix it, and teach the underlying concept clearly.\n\n${code}`,
          },
        ],
      }),
    });
  } catch (err) {
    console.error('[ai] upstream fetch threw:', err);
    res.status(502).json({ error: `Failed to reach ${API_BASE}: ${err.message ?? err}` });
    return;
  }

  if (!upstream.ok) {
    const body = await upstream.text();
    console.warn('[ai] upstream returned', upstream.status, body.slice(0, 500));
    res.status(upstream.status).send(body);
    return;
  }

  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  if (typeof res.flushHeaders === 'function') res.flushHeaders();

  // Abort the upstream request if the browser disconnects mid-stream.
  const controller = new AbortController();
  req.on('close', () => controller.abort());

  const reader = upstream.body.getReader();
  const decoder = new TextDecoder();
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      res.write(decoder.decode(value, { stream: true }));
    }
  } catch (err) {
    if (controller.signal.aborted) {
      // Client went away — nothing to do.
    } else {
      console.error('[ai] Stream relay failed:', err);
    }
  } finally {
    res.end();
  }
});

app.listen(PORT, () => {
  const dot = API_KEY ? '✓' : '✗';
  console.log(`[ai] Code-Buddy AI relay listening on http://localhost:${PORT}`);
  console.log(`[ai] Upstream: ${API_BASE}`);
  console.log(`[ai] Model:    ${MODEL}`);
  console.log(`[ai] API key:  ${dot}`);
  if (!API_KEY) {
    console.log('[ai] Add your key to server/.env to enable real responses.');
  }
});
