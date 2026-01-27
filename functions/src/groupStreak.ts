/**
 * Group Streak Cloud Functions
 *
 * This module contains scheduled functions for managing group streaks:
 * - evaluateGroupStreaks: Runs Sunday 23:59 UTC to evaluate weekly compliance
 * - createWeeklyStreakWeek: Runs Monday 00:00 UTC to create new week records
 * - sendAtRiskNotifications: Runs Thursday 18:00 UTC to notify at-risk members
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// Constants
const REQUIRED_WORKOUTS = 3;
const STREAK_INCREMENT_DAYS = 7;

// Milestones in days
const MILESTONES = [7, 14, 30, 60, 100];

// Types
interface MemberWeeklyStatus {
  displayName: string;
  photoURL?: string;
  workoutCount: number;
  lastWorkoutDate?: admin.firestore.Timestamp;
}

interface GroupStreakWeek {
  groupId: string;
  weekStartDate: admin.firestore.Timestamp;
  weekEndDate: admin.firestore.Timestamp;
  memberCompliance: Record<string, MemberWeeklyStatus>;
  allCompliant?: boolean;
  createdAt: admin.firestore.Timestamp;
}

interface GroupStreak {
  groupStreakDays: number;
  lastMilestone?: number;
  streakStartDate?: admin.firestore.Timestamp;
  pausedUntil?: admin.firestore.Timestamp;
  pauseUsedThisMonth: boolean;
}

// ============================================================================
// Task 11: Weekly Streak Evaluation (Sunday 23:59 UTC)
// ============================================================================

/**
 * Evaluates all group streaks at the end of each week.
 * - If all members are compliant: increment streak by 7 days
 * - If any member failed: reset streak to 0
 * - Sends notifications for milestones or broken streaks
 *
 * Schedule: Every Sunday at 23:59 UTC (59 23 * * 0)
 */
export const evaluateGroupStreaks = functions.pubsub
  .schedule("59 23 * * 0")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("[evaluateGroupStreaks] Starting weekly evaluation...");

    try {
      // Get all groups with active streaks
      const groupsSnapshot = await db
        .collection("groups")
        .where("isActive", "==", true)
        .get();

      console.log(`[evaluateGroupStreaks] Found ${groupsSnapshot.size} active groups`);

      const batch = db.batch();
      const notifications: Promise<void>[] = [];

      for (const groupDoc of groupsSnapshot.docs) {
        const groupId = groupDoc.id;
        const groupData = groupDoc.data();

        // Get streak status
        const streakRef = db.doc(`groups/${groupId}/streak/status`);
        const streakDoc = await streakRef.get();
        const streakData = streakDoc.data() as GroupStreak | undefined;

        // Skip if paused
        if (streakData?.pausedUntil) {
          const pausedUntil = streakData.pausedUntil.toDate();
          if (new Date() < pausedUntil) {
            console.log(`[evaluateGroupStreaks] Group ${groupId} is paused until ${pausedUntil}`);
            continue;
          }
        }

        // Get current week record
        const weekBounds = getCurrentWeekBounds();
        const weekSnapshot = await db
          .collection(`groups/${groupId}/streakWeeks`)
          .where("weekStartDate", "==", weekBounds.start)
          .limit(1)
          .get();

        if (weekSnapshot.empty) {
          console.log(`[evaluateGroupStreaks] No week record for group ${groupId}`);
          continue;
        }

        const weekDoc = weekSnapshot.docs[0];
        const weekData = weekDoc.data() as GroupStreakWeek;
        const memberCompliance = weekData.memberCompliance || {};

        // Check if all members are compliant
        const allCompliant = Object.values(memberCompliance).every(
          (member) => member.workoutCount >= REQUIRED_WORKOUTS
        );

        // Update week record with final compliance status
        batch.update(weekDoc.ref, { allCompliant });

        const currentStreakDays = streakData?.groupStreakDays || 0;

        if (allCompliant) {
          // Increment streak
          const newStreakDays = currentStreakDays + STREAK_INCREMENT_DAYS;
          const achievedMilestone = MILESTONES.find((m) => m === newStreakDays);

          const updateData: Partial<GroupStreak> = {
            groupStreakDays: newStreakDays,
          };

          if (achievedMilestone) {
            updateData.lastMilestone = achievedMilestone;
          }

          if (!streakData?.streakStartDate) {
            updateData.streakStartDate = admin.firestore.Timestamp.now();
          }

          batch.set(streakRef, updateData, { merge: true });

          console.log(
            `[evaluateGroupStreaks] Group ${groupId}: streak incremented to ${newStreakDays} days`
          );

          // Send milestone notification if applicable
          if (achievedMilestone) {
            notifications.push(
              sendMilestoneNotification(groupId, groupData.name, achievedMilestone)
            );
          }
        } else {
          // Reset streak
          batch.set(
            streakRef,
            {
              groupStreakDays: 0,
              lastMilestone: admin.firestore.FieldValue.delete(),
              streakStartDate: admin.firestore.FieldValue.delete(),
            },
            { merge: true }
          );

          console.log(`[evaluateGroupStreaks] Group ${groupId}: streak broken and reset`);

          // Send streak broken notification
          if (currentStreakDays > 0) {
            notifications.push(
              sendStreakBrokenNotification(groupId, groupData.name, currentStreakDays)
            );
          }
        }
      }

      // Commit all updates
      await batch.commit();
      console.log("[evaluateGroupStreaks] Batch committed successfully");

      // Wait for all notifications
      await Promise.all(notifications);
      console.log("[evaluateGroupStreaks] All notifications sent");

      return null;
    } catch (error) {
      console.error("[evaluateGroupStreaks] Error:", error);
      throw error;
    }
  });

// ============================================================================
// Task 12: Weekly Record Creation (Monday 00:00 UTC)
// ============================================================================

/**
 * Creates new week records for all active groups.
 * Initializes member compliance with workoutCount: 0 for all active members.
 *
 * Schedule: Every Monday at 00:00 UTC (0 0 * * 1)
 */
export const createWeeklyStreakWeek = functions.pubsub
  .schedule("0 0 * * 1")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("[createWeeklyStreakWeek] Starting weekly record creation...");

    try {
      // Get all active groups
      const groupsSnapshot = await db
        .collection("groups")
        .where("isActive", "==", true)
        .get();

      console.log(`[createWeeklyStreakWeek] Found ${groupsSnapshot.size} active groups`);

      const weekBounds = getCurrentWeekBounds();
      const batch = db.batch();

      for (const groupDoc of groupsSnapshot.docs) {
        const groupId = groupDoc.id;

        // Get active members
        const membersSnapshot = await db
          .collection(`groups/${groupId}/members`)
          .where("isActive", "==", true)
          .get();

        // Build member compliance map
        const memberCompliance: Record<string, MemberWeeklyStatus> = {};
        for (const memberDoc of membersSnapshot.docs) {
          const memberData = memberDoc.data();
          memberCompliance[memberDoc.id] = {
            displayName: memberData.displayName || "Unknown",
            photoURL: memberData.photoURL,
            workoutCount: 0,
          };
        }

        // Create new week record
        const weekRecord: GroupStreakWeek = {
          groupId,
          weekStartDate: weekBounds.start,
          weekEndDate: weekBounds.end,
          memberCompliance,
          createdAt: admin.firestore.Timestamp.now(),
        };

        const weekRef = db.collection(`groups/${groupId}/streakWeeks`).doc();
        batch.set(weekRef, weekRecord);

        console.log(
          `[createWeeklyStreakWeek] Created week record for group ${groupId} with ${membersSnapshot.size} members`
        );
      }

      // Commit all records
      await batch.commit();
      console.log("[createWeeklyStreakWeek] All week records created successfully");

      // Reset monthly pause flags on first Monday of month
      const now = new Date();
      if (now.getDate() <= 7) {
        await resetMonthlyPauseFlags();
      }

      return null;
    } catch (error) {
      console.error("[createWeeklyStreakWeek] Error:", error);
      throw error;
    }
  });

// ============================================================================
// Task 13: At-Risk Notifications (Thursday 18:00 UTC)
// ============================================================================

/**
 * Sends notifications to members who are at risk of breaking the streak.
 * Identifies members with < 2 workouts and notifies them and the group.
 *
 * Schedule: Every Thursday at 18:00 UTC (0 18 * * 4)
 */
export const sendAtRiskNotifications = functions.pubsub
  .schedule("0 18 * * 4")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("[sendAtRiskNotifications] Starting at-risk notification check...");

    try {
      // Get all active groups with streaks
      const groupsSnapshot = await db
        .collection("groups")
        .where("isActive", "==", true)
        .get();

      console.log(`[sendAtRiskNotifications] Found ${groupsSnapshot.size} active groups`);

      const notifications: Promise<void>[] = [];

      for (const groupDoc of groupsSnapshot.docs) {
        const groupId = groupDoc.id;
        const groupData = groupDoc.data();

        // Get streak status
        const streakDoc = await db.doc(`groups/${groupId}/streak/status`).get();
        const streakData = streakDoc.data() as GroupStreak | undefined;

        // Skip if no active streak or paused
        if (!streakData?.groupStreakDays || streakData.groupStreakDays === 0) {
          continue;
        }

        if (streakData.pausedUntil) {
          const pausedUntil = streakData.pausedUntil.toDate();
          if (new Date() < pausedUntil) {
            continue;
          }
        }

        // Get current week record
        const weekBounds = getCurrentWeekBounds();
        const weekSnapshot = await db
          .collection(`groups/${groupId}/streakWeeks`)
          .where("weekStartDate", "==", weekBounds.start)
          .limit(1)
          .get();

        if (weekSnapshot.empty) {
          continue;
        }

        const weekData = weekSnapshot.docs[0].data() as GroupStreakWeek;
        const memberCompliance = weekData.memberCompliance || {};

        // Find at-risk members (< 2 workouts, threshold for notification)
        const atRiskMembers = Object.entries(memberCompliance)
          .filter(([, member]) => member.workoutCount < 2)
          .map(([userId, member]) => ({
            userId,
            displayName: member.displayName,
            workoutCount: member.workoutCount,
            workoutsRemaining: REQUIRED_WORKOUTS - member.workoutCount,
          }));

        if (atRiskMembers.length === 0) {
          continue;
        }

        console.log(
          `[sendAtRiskNotifications] Group ${groupId}: ${atRiskMembers.length} at-risk members`
        );

        // Send individual notifications to at-risk members
        for (const member of atRiskMembers) {
          notifications.push(
            sendIndividualAtRiskNotification(
              member.userId,
              groupId,
              groupData.name,
              member.workoutsRemaining,
              streakData.groupStreakDays
            )
          );
        }

        // Send group notification about at-risk members
        notifications.push(
          sendGroupAtRiskNotification(groupId, groupData.name, atRiskMembers)
        );
      }

      await Promise.all(notifications);
      console.log("[sendAtRiskNotifications] All notifications sent");

      return null;
    } catch (error) {
      console.error("[sendAtRiskNotifications] Error:", error);
      throw error;
    }
  });

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Gets the current week's start and end timestamps (Monday-Sunday UTC)
 */
function getCurrentWeekBounds(): {
  start: admin.firestore.Timestamp;
  end: admin.firestore.Timestamp;
} {
  const now = new Date();
  const dayOfWeek = now.getUTCDay();
  const daysToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() + daysToMonday);
  monday.setUTCHours(0, 0, 0, 0);

  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);
  sunday.setUTCHours(23, 59, 59, 999);

  return {
    start: admin.firestore.Timestamp.fromDate(monday),
    end: admin.firestore.Timestamp.fromDate(sunday),
  };
}

/**
 * Resets monthly pause flags for all groups
 */
async function resetMonthlyPauseFlags(): Promise<void> {
  console.log("[resetMonthlyPauseFlags] Resetting monthly pause flags...");

  const groupsSnapshot = await db.collection("groups").where("isActive", "==", true).get();

  const batch = db.batch();
  for (const groupDoc of groupsSnapshot.docs) {
    const streakRef = db.doc(`groups/${groupDoc.id}/streak/status`);
    batch.set(streakRef, { pauseUsedThisMonth: false }, { merge: true });
  }

  await batch.commit();
  console.log("[resetMonthlyPauseFlags] Monthly pause flags reset");
}

/**
 * Sends a milestone achievement notification to all group members
 */
async function sendMilestoneNotification(
  groupId: string,
  groupName: string,
  milestone: number
): Promise<void> {
  console.log(`[sendMilestoneNotification] Group ${groupId} achieved ${milestone}-day milestone`);

  const emoji = getMilestoneEmoji(milestone);
  const message = `${emoji} ${groupName} achieved a ${milestone}-day streak! Amazing teamwork!`;

  await createGroupNotification(groupId, "milestone", message);
}

/**
 * Sends a streak broken notification to all group members
 */
async function sendStreakBrokenNotification(
  groupId: string,
  groupName: string,
  previousDays: number
): Promise<void> {
  console.log(`[sendStreakBrokenNotification] Group ${groupId} streak broken at ${previousDays} days`);

  const message = `The ${groupName} ${previousDays}-day streak has ended. Time to start fresh!`;

  await createGroupNotification(groupId, "streak_broken", message);
}

/**
 * Sends an individual at-risk notification to a specific member
 */
async function sendIndividualAtRiskNotification(
  userId: string,
  groupId: string,
  groupName: string,
  workoutsRemaining: number,
  streakDays: number
): Promise<void> {
  console.log(`[sendIndividualAtRiskNotification] Notifying user ${userId}`);

  const message = `Streak alert! Complete ${workoutsRemaining} more workout${workoutsRemaining > 1 ? "s" : ""} by Sunday to keep the ${groupName} ${streakDays}-day streak alive!`;

  await db.collection("notifications").add({
    userId,
    groupId,
    type: "at_risk",
    message,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Sends a group notification about at-risk members
 */
async function sendGroupAtRiskNotification(
  groupId: string,
  groupName: string,
  atRiskMembers: Array<{ displayName: string; workoutCount: number }>
): Promise<void> {
  console.log(`[sendGroupAtRiskNotification] Notifying group ${groupId} about at-risk members`);

  const memberList = atRiskMembers
    .map((m) => `${m.displayName} (${m.workoutCount}/3)`)
    .join(", ");

  const message = `Streak at risk! These members need more workouts by Sunday: ${memberList}`;

  await createGroupNotification(groupId, "group_at_risk", message);
}

/**
 * Creates a notification for all members of a group
 */
async function createGroupNotification(
  groupId: string,
  type: string,
  message: string
): Promise<void> {
  // Get all active members
  const membersSnapshot = await db
    .collection(`groups/${groupId}/members`)
    .where("isActive", "==", true)
    .get();

  const batch = db.batch();
  for (const memberDoc of membersSnapshot.docs) {
    const notificationRef = db.collection("notifications").doc();
    batch.set(notificationRef, {
      userId: memberDoc.id,
      groupId,
      type,
      message,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}

/**
 * Gets the emoji for a milestone
 */
function getMilestoneEmoji(milestone: number): string {
  switch (milestone) {
    case 7:
      return "\uD83D\uDD25"; // Fire
    case 14:
      return "\uD83D\uDCAA"; // Flexed biceps
    case 30:
      return "\u2B50"; // Star
    case 60:
      return "\uD83C\uDFC6"; // Trophy
    case 100:
      return "\uD83D\uDC51"; // Crown
    default:
      return "\uD83C\uDF89"; // Party popper
  }
}
