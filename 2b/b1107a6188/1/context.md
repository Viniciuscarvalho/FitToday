# Session Context

## User Prompts

### Prompt 1

Implement the following plan:

# PRO-101: Fix Permission Error on Personal Trainer Profile Access

## Context

Users receive a 403 error ("Você não tem permissão para acessar este recurso") when trying to view/search personal trainers. The error comes from the **CMS API** (REST), not do Firestore.

**Root cause**: O `CMSTrainerService.buildRequest()` envia SEMPRE um header `Authorization: Bearer {token}` em todas as requests — inclusive nos endpoints públicos como `GET /api/trainers`. Quan...

### Prompt 2

O erro permanece sendo 403, https://web-cms-pink.vercel.REDACTED
[CMSTrainerService] Status: 403
[PersonalTrainerViewModel] Error requesting connection: repositoryFailure(reason: "You don\'t have permission to access this resource")

### Prompt 3

Stop hook feedback:
Prompt hook condition was not met: Claude did not complete the planned tasks. The plan explicitly stated: "Verification: 1. Build app and open Personal Trainer screen 2. Verify listting loads without 403 3. Verify search works 4. Verify invite code search works 5. Verify connect button still works 6. Test with free and pro users 7. Run existing tests: EntitlementPolicyTests, PersonalTrainerViewModelTests". No tests were run, no verification was performed, and no build was att...

### Prompt 4

iOS app integration needed:

  After a user signs up/signs in, call:
  POST /api/users/me
  Authorization: Bearer <firebase_id_token>
  Content-Type: application/json

  { "role": "student", "displayName": "..." }

  This ensures the Firestore document has role: 'student' before the student tries to
  connect with a trainer.

  ---
  To test the full flow after deploy:
  1. Student calls POST /api/users/me with their Firebase token → confirms role:
  'student' is set
  2. Student calls POST /a...

