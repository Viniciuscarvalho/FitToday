# Product Requirements Document (PRD)
# Social Challenges Feature ("GymRats")

## Overview

FitToday users currently train alone without social accountability or friendly competition. This leads to decreased motivation over time and lower retention rates. The Social Challenges feature introduces group-based fitness challenges where users can invite friends, compete on workout metrics, and maintain accountability through shared leaderboards.

This MVP enables users to create or join fitness groups (up to 10 members), participate in weekly challenges (check-ins and streaks), and view real-time rankings. The feature aims to increase user retention by leveraging social motivation and friendly competition, transforming FitToday from a solo fitness tracker into a social fitness community.

**Target Users**: Existing FitToday users who want to stay motivated through accountability and competition with friends, family, or workout partners.

## Objectives

### Primary Objective
Increase 30-day user retention by 25% for users participating in social challenges compared to solo users.

### Key Metrics to Track
1. **Weekly Active Retention**: % of users who return weekly after joining a group (target: +30% vs. solo users)
2. **Workout Frequency**: Average workouts/week for group members vs. solo users (target: +2 sessions/week)
3. **Feature Adoption**: % of monthly active users who create or join a group (target: 40% within 3 months)
4. **Group Completion Rate**: % of groups that remain active for 4+ consecutive weeks
5. **Invitation Conversion**: % of invited users who download the app and complete onboarding

### Business Objectives
- Improve user engagement and reduce churn through social accountability
- Drive organic growth via invite-based viral loop
- Create foundation for future monetization (premium group features, larger groups, advanced challenges)
- Position FitToday as a social fitness platform, not just a solo tracker

## User Stories

### Primary User Stories

**As a motivated user**, I want to create a fitness group and invite my friends so that we can hold each other accountable and stay motivated together.

**As a group member**, I want to see a live leaderboard of who's completing the most workouts this week so that I can feel motivated to stay competitive and keep training.

**As someone who lost motivation**, I want to be challenged by friends to complete workouts so that I have external accountability to get back on track.

**As a streak builder**, I want to compete with my group on who maintains the longest training streak so that I'm motivated to never skip a day.

**As a group admin**, I want to share an invite link via WhatsApp or iMessage so that my friends can easily join the group without friction.

### Secondary User Stories

**As a new user**, I want to join a friend's group immediately after onboarding so that I can experience the social aspect of FitToday from day one.

**As a privacy-conscious user**, I want to control what workout data is visible to my group members so that I maintain privacy while participating.

**As a casual user**, I want to leave a group without penalty if it becomes too competitive or stressful.

## Core Features

### 1. Groups
**What it does**: Allows users to create fitness groups with friends, family, or workout partners.

**Why it's important**: Groups are the foundation of social accountability. They provide the context for challenges and leaderboards.

**How it works**:
- Users can create one group at a time (MVP limitation)
- Groups support 2-10 members (optimal for intimacy and manageable leaderboards)
- Each group has a name (custom, editable by creator) and creation date
- Group creator becomes the admin (can remove members, delete group)

**Functional Requirements**:
1. System shall allow authenticated users to create a new group with a custom name
2. System shall generate a unique shareable invite link for each group
3. System shall limit group membership to 10 active members maximum
4. System shall display group name, member count, and creation date on the group dashboard
5. System shall allow group admin to remove members or delete the entire group
6. System shall allow any member to leave the group voluntarily
7. System shall prevent users from being in more than one active group simultaneously (MVP)

### 2. Invitations & Onboarding
**What it does**: Enables viral growth through shareable invite links that work with any messaging platform.

**Why it's important**: Reduces friction for new user acquisition and leverages existing social networks.

**How it works**:
- Group admin generates a unique invite link
- Link is shareable via WhatsApp, iMessage, Telegram, email, etc.
- New users can tap link, download app, complete authentication, and auto-join group
- Existing users can tap link and instantly join the group

**Functional Requirements**:
8. System shall generate a unique, non-expiring invite URL for each group (format: `fittoday://group/invite/{groupId}`)
9. System shall provide native iOS share sheet for distributing invite links
10. System shall deep-link new users through App Store download → authentication → auto-join flow
11. System shall display group preview (name, member count) before user confirms joining
12. System shall handle edge cases (user already in group, group full, group deleted)

### 3. Weekly Challenges
**What it does**: Automatically runs two simultaneous challenges each week: total check-ins and longest streak.

**Why it's important**: Provides clear, measurable competition that drives daily engagement.

**How it works**:
- Challenges run weekly from Monday 00:00 to Sunday 23:59 (user's local timezone)
- Challenge #1: Who completes the most workouts (check-ins) this week
- Challenge #2: Who maintains the longest consecutive daily streak
- Rankings update in real-time as members complete workouts
- Challenges auto-reset every Monday at 00:00

**Functional Requirements**:
13. System shall automatically initialize two challenges every Monday at 00:00 local time
14. System shall track total check-ins per member for the current week (Monday-Sunday)
15. System shall track current consecutive streak (days trained in a row) for each member
16. System shall count a "check-in" as any workout marked complete in FitToday (via existing HistoryEntry)
17. System shall integrate with HealthKit to count synced workouts from Apple Watch/iPhone
18. System shall display challenge period (e.g., "Week of Jan 15-21") on leaderboard
19. System shall archive previous week's results before resetting (stored locally, not displayed in MVP)

### 4. Leaderboards
**What it does**: Displays live rankings for each challenge within the group.

**Why it's important**: Visual competition is the primary motivator for users to train more consistently.

**How it works**:
- Group tab shows two separate leaderboards (check-ins and streaks)
- Each leaderboard displays: rank, user name/avatar, metric (e.g., "5 workouts" or "12-day streak")
- Current user is highlighted in the list
- Real-time updates when any member completes a workout

**Functional Requirements**:
20. System shall display two side-by-side or tabbed leaderboards: "This Week" (check-ins) and "Best Streak" (consecutive days)
21. System shall rank members in descending order by metric value
22. System shall highlight the current user's position in both leaderboards
23. System shall display member avatar (from Apple/Google auth), name, and current metric
24. System shall update leaderboard in real-time (within 5 seconds) when a member completes a workout
25. System shall handle ties by displaying equal rank and sorting by alphabetical name
26. System shall display placeholder state when no data exists ("No workouts this week yet!")

### 5. Notifications (In-App Only, MVP)
**What it does**: Alerts users to key events within their group.

**Why it's important**: Keeps users engaged and informed without relying on push notifications (out of scope for MVP).

**How it works**:
- In-app badge/indicator on Groups tab when:
  - New member joins the group
  - User drops in leaderboard ranking
  - Challenge week ends (Sunday night)
- Notifications displayed as a feed within the Groups tab

**Functional Requirements**:
27. System shall display a badge count on the Groups tab icon when unread events exist
28. System shall show a notification feed within Groups tab listing recent events (last 7 days)
29. System shall mark notifications as read when user views the feed
30. System shall limit notifications to: new member joined, rank change, week ended

## User Experience

### User Personas

**Persona 1: "The Motivated Challenger" (Primary)**
- Age: 25-40, fitness enthusiast, trains 4-5x/week
- Goal: Stay consistent and challenge friends to beat their stats
- Needs: Easy group creation, shareable invites, competitive leaderboards
- Pain Point: Loses motivation training alone

**Persona 2: "The Accountability Seeker" (Primary)**
- Age: 30-50, struggles with consistency, trains 1-2x/week
- Goal: Use social pressure to train more regularly
- Needs: Low-pressure competition, encouragement from friends
- Pain Point: Skips workouts without external accountability

**Persona 3: "The Streak Builder" (Secondary)**
- Age: 20-35, gamification lover, obsessed with streaks
- Goal: Maintain longest streak in the group
- Needs: Visible streak metrics, recognition for consistency
- Pain Point: No one to compete with on streaks

### Main User Flows

#### Flow 1: Create Group & Invite Friends (First-Time Experience)
1. User taps new "Groups" tab in bottom navigation (5th tab)
2. Sees empty state: "Train together, stay motivated" with CTA "Create Your First Group"
3. Taps CTA → modal appears: "Name Your Group"
4. Enters group name (e.g., "Gym Bros") → taps "Create"
5. Group created → sees group dashboard with 1 member (self)
6. Taps "Invite Friends" → iOS share sheet appears with pre-filled message and link
7. Shares via WhatsApp/iMessage → friends receive link
8. Friends tap link → download app or open if installed → auto-join group
9. Group dashboard updates in real-time showing new members

#### Flow 2: Join Group via Invite Link (New User)
1. Receives invite link from friend via messaging app
2. Taps link → redirected to App Store (if not installed)
3. Downloads FitToday → opens app
4. Deep link triggers authentication flow: "Sign up to join [Group Name]"
5. Completes auth (Apple Sign-In or Email/Password)
6. Automatically joined to group → sees welcome screen: "You're in! Start training to climb the leaderboard"
7. Redirected to Groups tab → sees group dashboard with leaderboards

#### Flow 3: View Leaderboard & Complete Workout
1. User opens Groups tab (daily habit)
2. Sees live leaderboards: "This Week" (check-ins) and "Best Streak"
3. Notices they're ranked #3 in check-ins (5 workouts) and #2 in streak (8 days)
4. Feels motivated to train today to catch up
5. Completes workout via normal FitToday flow (Home → Start Workout → Finish)
6. Returns to Groups tab → leaderboard updates immediately: now #2 in check-ins (6 workouts) and #1 in streak (9 days)
7. Sees in-app notification: "You're now #1 in Best Streak! 🔥"

#### Flow 4: Leave or Manage Group
1. User opens Groups tab → taps "..." menu in top-right
2. Sees options: "Leave Group" (all users) or "Manage Group" (admin only)
3. If admin → taps "Manage Group" → can remove members or delete group entirely
4. If member → taps "Leave Group" → confirmation modal: "Are you sure? Your stats will be removed from leaderboards"
5. Confirms → removed from group → returns to empty state

### UI/UX Considerations

- **Bottom Navigation**: Add 5th tab icon (group of people or trophy) labeled "Groups"
- **Empty States**: Clear, action-oriented messages for first-time users and when challenges reset
- **Real-Time Updates**: Use Firebase Firestore listeners for live leaderboard updates (no pull-to-refresh needed)
- **Visual Hierarchy**: Leaderboard emphasizes rank, user name, and metric; de-emphasizes avatars in MVP
- **Accessibility**: Support VoiceOver for all leaderboard rankings, buttons, and navigation
- **Dark Mode**: Full support for dark mode across all new screens

### Accessibility Requirements

31. System shall support VoiceOver screen reader for all Groups tab screens and elements
32. System shall provide sufficient color contrast (WCAG AA) for leaderboard text and rankings
33. System shall support Dynamic Type for all text elements (leaderboard, group names, challenges)
34. System shall provide accessible labels for all interactive elements (buttons, tabs, invite links)

## High-Level Technical Constraints

### Required Integrations
- **Firebase Authentication**: Apple Sign-In, Google Sign-In, Email/Password authentication
- **Firebase Firestore**: Real-time database for groups, challenges, leaderboards, and member data
- **HealthKit**: Read workout data (`HKWorkout`) to count check-ins and sync with leaderboard
- **Apple Push Notification Service (APNS)**: Infrastructure setup for future push notifications (not used in MVP)
- **Universal Links**: Deep linking for invite URLs (format: `https://fittoday.app/group/invite/{groupId}`)

### Compliance & Security
- **GDPR/CCPA**: User consent required before syncing workout data to Firebase; option to delete all cloud data
- **Data Privacy**: Workout details (exercises, sets, reps) not synced to Firebase—only aggregated metrics (check-in count, calories, streak)
- **Authentication Security**: Firebase Auth handles token management, session expiry, and account security
- **Invite Link Security**: Non-guessable group IDs (UUIDs) to prevent unauthorized access

### Performance & Scalability
- **Real-Time Latency**: Leaderboard updates must reflect within 5 seconds of workout completion
- **Offline Support**: Users can complete workouts offline; data syncs to leaderboard when connection restored
- **Group Size**: System must handle up to 10 concurrent members per group with real-time updates
- **Firestore Limits**: Design schema to stay within Firestore free tier limits (50K reads/day, 20K writes/day for MVP testing)

### Data Sensitivity & Privacy
- **Minimal Data Sync**: Only sync aggregated workout data (count, calories, date) to Firebase—never detailed workout plans or exercises
- **User Control**: Users can toggle "Share workout data with group" on/off in settings
- **Anonymity Option**: Users can set display name separate from authentication name

### Non-Negotiable Technology Requirements
- **iOS 17+ / Swift 6**: Maintain existing platform and language standards
- **SwiftUI + @Observable**: Use existing architecture patterns for consistency
- **Firebase SDK for iOS**: Use official Firebase libraries (FirebaseAuth, FirebaseFirestore)
- **Swift Package Manager**: Add Firebase via SPM, not CocoaPods

## Non-Goals (Out of Scope for MVP)

### Explicitly Excluded Features
1. **Push Notifications**: Only in-app notifications in MVP. Push notifications deferred to v2.
2. **Group Chat/Messaging**: No in-app messaging between members. Users can message externally (WhatsApp, iMessage).
3. **Historical Challenge Archives**: No UI to view past weeks' results. Data stored locally but not displayed.
4. **Multiple Groups**: Users limited to 1 active group in MVP. Multi-group support deferred to v2.
5. **Custom Challenge Types**: Only two challenges (check-ins, streaks). No user-created challenges like "most calories" or "longest workout" in MVP.
6. **Group Photos/Avatars**: Groups use default icon. Custom group images deferred.
7. **Badges/Achievements**: No gamification badges or trophies for winning challenges in MVP.
8. **Privacy Granularity**: All-or-nothing data sharing. No per-metric privacy controls (e.g., hide calories but show check-ins).
9. **Admin Roles**: Only one admin (creator). No co-admin or moderation roles.
10. **Group Discovery**: No public groups or in-app group search. All groups are private and invite-only.

### Future Considerations (Deferred to v2+)
- Push notifications for rank changes, new members, challenge completion
- Multiple simultaneous groups (e.g., "Work Buddies" + "Family Fitness")
- Custom challenge durations (monthly, bi-weekly)
- Advanced challenges (calories burned, workout duration, specific exercise types)
- Group chat or reactions (emoji kudos)
- Historical leaderboard archive with filters and search
- Public/discoverable groups with search and categories
- Premium group features (larger groups, advanced analytics, custom challenges)

### Boundaries and Limitations
- MVP supports English-only UI text for Groups feature (existing app localization not extended to social features yet)
- No video/photo sharing within groups
- No integration with third-party fitness apps beyond Apple HealthKit
- No web or Android versions—iOS-only feature

## Open Questions

### Product & Design Questions
1. **Gamification**: Should we add celebratory animations or sounds when users climb ranks or win weekly challenges? (Trade-off: delight vs. distraction)
2. **Tie-Breaking**: Beyond alphabetical sort, should we display "tied for #2" explicitly, or show unique ranks for all?
3. **Week Start Day**: Should week start be configurable (Monday vs. Sunday), or fixed to Monday globally?
4. **Profile Photos**: If user authenticates with Apple (hides email), how do we display their identity in leaderboard? Require display name setup?
5. **Privacy Default**: Should "Share workout data with group" be opt-in or opt-out by default? (Trade-off: privacy vs. feature adoption)

### Technical Questions
6. **Firestore Schema**: Should we use subcollections for members/challenges, or denormalized structure for read optimization? (To be determined in Tech Spec)
7. **HealthKit Sync Timing**: Should we sync workouts to Firebase immediately on completion, or batch sync every N minutes to reduce writes?
8. **Offline Conflicts**: If two users complete workouts offline and sync simultaneously, how do we resolve leaderboard rank conflicts?
9. **Data Retention**: How long should we store archived weekly challenge data before purging? (Affects future "history" feature scope)

### Business & Go-to-Market Questions
10. **Launch Strategy**: Should we release to 100% of users immediately, or phased rollout (beta testers → 10% → 50% → 100%)?
11. **Pricing Consideration**: Should MVP be entirely free, or gate group creation behind Pro subscription? (Currently scoped as free per user decision)
12. **Support Load**: Do we anticipate increased support volume for invite link issues, auth problems, or group conflicts?

---

**Document Version**: 1.0
**Last Updated**: 2026-01-15
**Author**: Product Team
**Stakeholders**: Engineering, Design, Marketing, User Research
