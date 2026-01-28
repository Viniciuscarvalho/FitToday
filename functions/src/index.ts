/**
 * FitToday Cloud Functions
 *
 * This is the main entry point for all Firebase Cloud Functions.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export Group Streak functions
export {
  evaluateGroupStreaks,
  createWeeklyStreakWeek,
  sendAtRiskNotifications,
} from "./groupStreak";
