import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";

initializeApp();

const openaiKey = defineSecret("OPENAI_API_KEY");

const SYSTEM_PROMPT =
  "You are a beginner-friendly coding tutor. Explain errors clearly and teach concepts in simple language.";

const ALLOWED_MODELS = new Set(["gpt-4o-mini", "gpt-4o"]);

/**
 * Server-side relay for the Code-Buddy AI tutor.
 *
 * Browser flow:
 *   1. Client obtains a Firebase ID token from the signed-in user.
 *   2. Client POSTs JSON { code, language, model? } with
 *      "Authorization: Bearer <idToken>" to this endpoint.
 *   3. We verify the token, call OpenAI with stream:true, and pipe the SSE
 *      response straight back to the browser. The OpenAI key never leaves
 *      this function.
 */
export const debugCode = onRequest(
  {
    region: "us-central1",
    cors: true,
    secrets: [openaiKey],
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (req, res): Promise<void> => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      res.status(401).send("Missing bearer token");
      return;
    }
    const idToken = authHeader.substring(7);
    try {
      await getAuth().verifyIdToken(idToken);
    } catch (err) {
      console.warn("Token verification failed", err);
      res.status(401).send("Invalid token");
      return;
    }

    const { code, language, model } = (req.body ?? {}) as {
      code?: string;
      language?: string;
      model?: string;
    };

    if (!code || !language) {
      res.status(400).send("Missing 'code' or 'language' in request body");
      return;
    }
    const requestedModel = model && ALLOWED_MODELS.has(model) ? model : "gpt-4o-mini";

    res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no");
    res.flushHeaders?.();

    let openaiResp: Response;
    try {
      openaiResp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openaiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: requestedModel,
          temperature: 0.25,
          stream: true,
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            {
              role: "user",
              content:
                `Analyze this ${language} code. Explain errors, fix it, and teach the concept:\n\n${code}`,
            },
          ],
        }),
      });
    } catch (err) {
      console.error("OpenAI fetch threw", err);
      res.write(
        `data: ${JSON.stringify({ error: "Failed to reach OpenAI" })}\n\n`
      );
      res.end();
      return;
    }

    if (!openaiResp.ok || !openaiResp.body) {
      const body = await openaiResp.text();
      console.warn("OpenAI returned", openaiResp.status, body.slice(0, 500));
      res.status(openaiResp.status);
      res.write(`data: ${JSON.stringify({ error: body })}\n\n`);
      res.end();
      return;
    }

    const reader = openaiResp.body.getReader();
    const decoder = new TextDecoder();

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        res.write(decoder.decode(value, { stream: true }));
      }
    } catch (err) {
      console.error("Stream relay failed", err);
    } finally {
      res.end();
    }
  }
);
