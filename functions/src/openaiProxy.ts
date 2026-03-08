/**
 * OpenAI Proxy Cloud Functions
 *
 * Proxies OpenAI API calls through Firebase Functions so the API key
 * never leaves the server. All callers must be authenticated via Firebase Auth.
 */

import * as functions from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import OpenAI from "openai";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

const MODEL = "gpt-4o-mini";

const WORKOUT_SYSTEM_MESSAGE =
  "You are an expert personal trainer who creates personalized workout " +
  "plans. Always respond with valid JSON following the requested schema.";

/**
 * generateWorkout — Callable function for AI workout generation.
 *
 * Expects: { prompt: string }
 * Returns: Full OpenAI ChatCompletion response (JSON) so the iOS client
 *          can decode it with its existing ChatCompletionResponse struct.
 */
export const generateWorkout = functions
  .runWith({secrets: [openaiApiKey]})
  .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required to use AI features."
      );
    }

    // 2. Validate input
    const prompt = data?.prompt;
    if (!prompt || typeof prompt !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A 'prompt' string is required."
      );
    }

    // 3. Call OpenAI
    try {
      const client = new OpenAI({apiKey: openaiApiKey.value()});

      const response = await client.chat.completions.create({
        model: MODEL,
        messages: [
          {role: "system", content: WORKOUT_SYSTEM_MESSAGE},
          {role: "user", content: prompt},
        ],
        max_tokens: 2000,
        temperature: 0.55,
        response_format: {type: "json_object"},
      });

      // Return the full response structure so iOS can decode it
      return {
        choices: response.choices.map((choice) => ({
          message: {
            content: choice.message.content,
          },
        })),
      };
    } catch (error: unknown) {
      return handleOpenAIError(error);
    }
  });

/**
 * sendChat — Callable function for AI chat (FitOrb).
 *
 * Expects: { messages: [{role, content}], maxTokens?: number, temperature?: number }
 * Returns: { content: string }
 */
export const sendChat = functions
  .runWith({secrets: [openaiApiKey]})
  .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required to use AI features."
      );
    }

    // 2. Validate input
    const messages = data?.messages;
    if (!Array.isArray(messages) || messages.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A non-empty 'messages' array is required."
      );
    }

    const maxTokens = data?.maxTokens ?? 1000;
    const temperature = data?.temperature ?? 0.7;

    // 3. Call OpenAI
    try {
      const client = new OpenAI({apiKey: openaiApiKey.value()});

      const response = await client.chat.completions.create({
        model: MODEL,
        messages: messages.map(
          (m: {role: string; content: string}) => ({
            role: m.role as "system" | "user" | "assistant",
            content: m.content,
          })
        ),
        max_tokens: maxTokens,
        temperature: temperature,
      });

      const content = response.choices[0]?.message?.content ?? "";

      return {content};
    } catch (error: unknown) {
      return handleOpenAIError(error);
    }
  });

/**
 * Maps OpenAI SDK errors to Firebase HttpsError codes.
 */
function handleOpenAIError(error: unknown): never {
  if (error instanceof OpenAI.APIError) {
    const status = error.status;
    if (status === 429) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "OpenAI rate limit reached. Please try again later."
      );
    }
    if (status && status >= 400 && status < 500) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `OpenAI request error: ${error.message}`
      );
    }
    throw new functions.https.HttpsError(
      "internal",
      `OpenAI server error: ${error.message}`
    );
  }

  const message = error instanceof Error ? error.message : "Unknown error";
  throw new functions.https.HttpsError("internal", message);
}
