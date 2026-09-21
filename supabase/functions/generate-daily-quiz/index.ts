import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function pakistanDate(date = new Date()): string {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Karachi', year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(date);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

function daysAgoDate(days: number): string {
  const d = new Date(Date.now() - days * 86400000);
  return pakistanDate(d);
}

function normalizeQuestion(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9\u0600-\u06ff]+/g, ' ').trim().replace(/\s+/g, ' ');
}

async function sha256(text: string): Promise<string> {
  const bytes = new TextEncoder().encode(text);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

type GeneratedQuestion = {
  question: string;
  options: string[];
  correctIndex: number;
  hint: string;
};

function validateQuestion(q: unknown): GeneratedQuestion | null {
  if (!q || typeof q !== 'object') return null;
  const x = q as Record<string, unknown>;
  const question = String(x.question ?? '').trim();
  const hint = String(x.hint ?? '').trim();
  const options = Array.isArray(x.options) ? x.options.map((v) => String(v).trim()) : [];
  const correctIndex = Number(x.correctIndex);
  if (question.length < 8 || question.length > 500) return null;
  if (hint.length < 3 || hint.length > 300) return null;
  if (options.length !== 4 || options.some((o) => o.length < 1 || o.length > 180)) return null;
  if (new Set(options.map((o) => o.toLowerCase())).size !== 4) return null;
  if (!Number.isInteger(correctIndex) || correctIndex < 0 || correctIndex > 3) return null;
  return { question, options, correctIndex, hint };
}

async function geminiBatch(apiKey: string, exclusions: string[], batchSize = 20): Promise<GeneratedQuestion[]> {
  const model = 'gemini-3.5-flash-lite';
  const schema = {
    type: 'object',
    properties: {
      questions: {
        type: 'array',
        minItems: batchSize,
        maxItems: batchSize,
        items: {
          type: 'object',
          properties: {
            question: { type: 'string' },
            options: { type: 'array', minItems: 4, maxItems: 4, items: { type: 'string' } },
            correctIndex: { type: 'integer', minimum: 0, maximum: 3 },
            hint: { type: 'string' },
          },
          required: ['question', 'options', 'correctIndex', 'hint'],
        },
      },
    },
    required: ['questions'],
  };

  const avoid = exclusions.slice(-350).join('\n- ');
  const prompt = `Create exactly ${batchSize} fresh single-answer General Knowledge multiple-choice questions for a daily mobile quiz.
Rules:
- General Knowledge only. No arithmetic exercises, grammar drills, coding questions, riddles, political campaigning, election predictions, adult content, or unsafe material.
- Prefer stable facts from geography, history, culture, inventions, famous landmarks, nature, everyday science, world knowledge, and Pakistan/world GK.
- Avoid time-sensitive current office-holders and facts likely to become outdated quickly.
- Each question must have exactly 4 distinct plausible options and exactly one objectively correct answer.
- correctIndex is zero-based (0=A, 1=B, 2=C, 3=D).
- Hint must help without naming or directly revealing the correct option.
- Keep wording concise, factual, and suitable for a broad teen/adult audience.
- Do not repeat any question from the exclusion list below, and do not repeat concepts within this batch.

Exclusion list:
- ${avoid || 'None'}

Before output, internally verify every correct answer.`;

  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        responseSchema: schema,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini error ${response.status}: ${await response.text()}`);
  }
  const payload = await response.json();
  const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== 'string') throw new Error('Gemini returned no structured text');
  const parsed = JSON.parse(text);
  const raw = Array.isArray(parsed?.questions) ? parsed.questions : [];
  return raw.map(validateQuestion).filter((q): q is GeneratedQuestion => q !== null);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) throw new Error('GEMINI_API_KEY is not configured in Supabase Edge Function secrets.');

    const authHeader = req.headers.get('Authorization') ?? '';
    const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    const service = createClient(supabaseUrl, serviceRole);
    const body = req.method === 'POST' ? await req.json().catch(() => ({})) : {};
    const force = body?.force === true;
    if (force) {
      const { data: profile } = await service.from('profiles').select('role,is_banned').eq('id', userData.user.id).single();
      if (!profile || profile.role !== 'admin' || profile.is_banned) {
        return new Response(JSON.stringify({ error: 'Admin required' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    }

    const today = pakistanDate();
    const { data: quiz } = await service.from('daily_quizzes').select('*').eq('quiz_date', today).maybeSingle();
    const { count: existingCount } = await service.from('questions').select('id', { count: 'exact', head: true }).eq('quiz_date', today);

    if (!force && quiz?.status === 'published' && existingCount === 60) {
      return new Response(JSON.stringify({ status: 'published', quiz_date: today, count: 60 }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (!force && quiz?.status === 'generating' && quiz.created_at) {
      const age = Date.now() - new Date(quiz.created_at).getTime();
      if (age < 5 * 60 * 1000) {
        return new Response(JSON.stringify({ status: 'generating', quiz_date: today }), { status: 202, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    }

    if (force) {
      const { count: attempts } = await service.from('quiz_attempts').select('id', { count: 'exact', head: true }).eq('quiz_date', today);
      if ((attempts ?? 0) > 0) {
        return new Response(JSON.stringify({ error: 'Cannot regenerate after users have started today’s quiz.' }), { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    }

    await service.from('questions').delete().eq('quiz_date', today);
    await service.from('daily_quizzes').upsert({ quiz_date: today, status: 'generating', generated_by: 'gemini-3.5-flash-lite', created_at: new Date().toISOString(), published_at: null });

    try {
      const { data: recentRows } = await service
        .from('questions')
        .select('question_text')
        .gte('quiz_date', daysAgoDate(30))
        .neq('quiz_date', today)
        .order('created_at', { ascending: false })
        .limit(1800);

      const exclusionSet = new Set<string>((recentRows ?? []).map((r) => normalizeQuestion(r.question_text)));
      const exclusionDisplay = (recentRows ?? []).slice(0, 350).map((r) => r.question_text);
      const chosen: GeneratedQuestion[] = [];
      const chosenNorm = new Set<string>();

      for (let attempt = 0; attempt < 8 && chosen.length < 60; attempt++) {
        const wanted = Math.min(20, 60 - chosen.length);
        const generated = await geminiBatch(geminiKey, [...exclusionDisplay, ...chosen.map((q) => q.question)], wanted);
        for (const q of generated) {
          const norm = normalizeQuestion(q.question);
          if (!norm || exclusionSet.has(norm) || chosenNorm.has(norm)) continue;
          chosenNorm.add(norm);
          chosen.push(q);
          if (chosen.length >= 60) break;
        }
      }

      if (chosen.length !== 60) throw new Error(`Only ${chosen.length}/60 unique questions passed validation.`);

      const rows = [];
      for (let i = 0; i < chosen.length; i++) {
        const q = chosen[i];
        rows.push({
          quiz_date: today,
          position: i + 1,
          question_text: q.question,
          options: q.options,
          correct_index: q.correctIndex,
          hint: q.hint,
          question_hash: await sha256(normalizeQuestion(q.question)),
        });
      }

      const { error: insertError } = await service.from('questions').insert(rows);
      if (insertError) throw insertError;
      await service.from('daily_quizzes').update({ status: 'published', published_at: new Date().toISOString() }).eq('quiz_date', today);
      return new Response(JSON.stringify({ status: 'published', quiz_date: today, count: 60 }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    } catch (generationError) {
      await service.from('daily_quizzes').update({ status: 'failed' }).eq('quiz_date', today);
      throw generationError;
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
