/**
 * MyPA — AI Provider Adapter.
 * Ref: Technical Design Document v1.3, Section 7.2
 * Ref: Architecture Document v1.4, Section 6.4
 *
 * OpenRouterAdapter is the default/primary implementation covering all 8
 * launch providers via one API key and one OpenAI-compatible endpoint.
 * Direct per-provider adapters remain a documented fallback (not built here)
 * for a provider that needs to bypass OpenRouter.
 */

export interface GenerationParams {
  /** Pre-check cap from ai-generate (TDD Section 5) — bounds worst-case cost. */
  maxOutputTokens: number;
  temperature?: number;
}

export interface GenerationResult {
  text: string;
  promptTokens: number;
  completionTokens: number;
}

export interface AIProviderAdapter {
  generate(
    modelSlug: string,
    prompt: string,
    params: GenerationParams,
  ): Promise<GenerationResult>;
}

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY') ?? '';
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';

export class OpenRouterAdapter implements AIProviderAdapter {
  async generate(
    modelSlug: string,
    prompt: string,
    params: GenerationParams,
  ): Promise<GenerationResult> {
    if (!OPENROUTER_API_KEY) {
      throw new Error(
        'OPENROUTER_API_KEY is not set. Set it via `supabase secrets set` — ' +
          'see docs/06-environment/MyPA_Environment_Setup_v1.0.docx.',
      );
    }

    const response = await fetch(`${OPENROUTER_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        // Required by OpenRouter for attribution — update to the real
        // production domain/app name once deployed.
        'HTTP-Referer': 'https://mypa.app',
        'X-Title': 'MyPA',
      },
      body: JSON.stringify({
        model: modelSlug,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: params.maxOutputTokens,
        temperature: params.temperature ?? 0.7,
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`OpenRouter request failed (${response.status}): ${errorBody}`);
    }

    const data = await response.json();
    const text: string = data.choices?.[0]?.message?.content ?? '';
    const promptTokens: number = data.usage?.prompt_tokens ?? 0;
    const completionTokens: number = data.usage?.completion_tokens ?? 0;

    return { text, promptTokens, completionTokens };
  }
}
