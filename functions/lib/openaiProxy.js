"use strict";
/**
 * OpenAI Proxy Cloud Functions
 *
 * Proxies OpenAI API calls through Firebase Functions so the API key
 * never leaves the server. All callers must be authenticated via Firebase Auth.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendChat = exports.generateWorkout = void 0;
const functions = __importStar(require("firebase-functions"));
const params_1 = require("firebase-functions/params");
const openai_1 = __importDefault(require("openai"));
const openaiApiKey = (0, params_1.defineSecret)("OPENAI_API_KEY");
const MODEL = "gpt-4o-mini";
const WORKOUT_SYSTEM_MESSAGE = "You are an expert personal trainer who creates personalized workout " +
    "plans. Always respond with valid JSON following the requested schema.";
/**
 * generateWorkout — Callable function for AI workout generation.
 *
 * Expects: { prompt: string }
 * Returns: Full OpenAI ChatCompletion response (JSON) so the iOS client
 *          can decode it with its existing ChatCompletionResponse struct.
 */
exports.generateWorkout = functions
    .runWith({ secrets: [openaiApiKey] })
    .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required to use AI features.");
    }
    // 2. Validate input
    const prompt = data?.prompt;
    if (!prompt || typeof prompt !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "A 'prompt' string is required.");
    }
    // 3. Call OpenAI
    try {
        const client = new openai_1.default({ apiKey: openaiApiKey.value() });
        const response = await client.chat.completions.create({
            model: MODEL,
            messages: [
                { role: "system", content: WORKOUT_SYSTEM_MESSAGE },
                { role: "user", content: prompt },
            ],
            max_tokens: 2000,
            temperature: 0.55,
            response_format: { type: "json_object" },
        });
        // Return the full response structure so iOS can decode it
        return {
            choices: response.choices.map((choice) => ({
                message: {
                    content: choice.message.content,
                },
            })),
        };
    }
    catch (error) {
        return handleOpenAIError(error);
    }
});
/**
 * sendChat — Callable function for AI chat (FitOrb).
 *
 * Expects: { messages: [{role, content}], maxTokens?: number, temperature?: number }
 * Returns: { content: string }
 */
exports.sendChat = functions
    .runWith({ secrets: [openaiApiKey] })
    .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required to use AI features.");
    }
    // 2. Validate input
    const messages = data?.messages;
    if (!Array.isArray(messages) || messages.length === 0) {
        throw new functions.https.HttpsError("invalid-argument", "A non-empty 'messages' array is required.");
    }
    const maxTokens = data?.maxTokens ?? 1000;
    const temperature = data?.temperature ?? 0.7;
    // 3. Call OpenAI
    try {
        const client = new openai_1.default({ apiKey: openaiApiKey.value() });
        const response = await client.chat.completions.create({
            model: MODEL,
            messages: messages.map((m) => ({
                role: m.role,
                content: m.content,
            })),
            max_tokens: maxTokens,
            temperature: temperature,
        });
        const content = response.choices[0]?.message?.content ?? "";
        return { content };
    }
    catch (error) {
        return handleOpenAIError(error);
    }
});
/**
 * Maps OpenAI SDK errors to Firebase HttpsError codes.
 */
function handleOpenAIError(error) {
    if (error instanceof openai_1.default.APIError) {
        const status = error.status;
        if (status === 429) {
            throw new functions.https.HttpsError("resource-exhausted", "OpenAI rate limit reached. Please try again later.");
        }
        if (status && status >= 400 && status < 500) {
            throw new functions.https.HttpsError("invalid-argument", `OpenAI request error: ${error.message}`);
        }
        throw new functions.https.HttpsError("internal", `OpenAI server error: ${error.message}`);
    }
    const message = error instanceof Error ? error.message : "Unknown error";
    throw new functions.https.HttpsError("internal", message);
}
//# sourceMappingURL=openaiProxy.js.map