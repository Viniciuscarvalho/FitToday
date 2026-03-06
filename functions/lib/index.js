"use strict";
/**
 * FitToday Cloud Functions
 *
 * This is the main entry point for all Firebase Cloud Functions.
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendChat = exports.generateWorkout = exports.sendAtRiskNotifications = exports.createWeeklyStreakWeek = exports.evaluateGroupStreaks = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK
admin.initializeApp();
// Export Group Streak functions
var groupStreak_1 = require("./groupStreak");
Object.defineProperty(exports, "evaluateGroupStreaks", { enumerable: true, get: function () { return groupStreak_1.evaluateGroupStreaks; } });
Object.defineProperty(exports, "createWeeklyStreakWeek", { enumerable: true, get: function () { return groupStreak_1.createWeeklyStreakWeek; } });
Object.defineProperty(exports, "sendAtRiskNotifications", { enumerable: true, get: function () { return groupStreak_1.sendAtRiskNotifications; } });
// Export OpenAI proxy functions
var openaiProxy_1 = require("./openaiProxy");
Object.defineProperty(exports, "generateWorkout", { enumerable: true, get: function () { return openaiProxy_1.generateWorkout; } });
Object.defineProperty(exports, "sendChat", { enumerable: true, get: function () { return openaiProxy_1.sendChat; } });
//# sourceMappingURL=index.js.map