/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

export const onFridgeMemberKicked = onDocumentUpdated(
  "fridges/{fridgeId}",
  async (event) => {
    const before = event.data?.before.data() as { sharedWith?: string[] };
    const after = event.data?.after.data() as { sharedWith?: string[] };
    const fridgeId = event.params.fridgeId;

    const beforeSharedWith: string[] = before?.sharedWith || [];
    const afterSharedWith: string[] = after?.sharedWith || [];

    // 강퇴된 uid 목록: before에는 있었으나 after에는 없는 uid
    const kickedUids: string[] = beforeSharedWith.filter(
      (uid: string) => !afterSharedWith.includes(uid)
    );

    const promises = kickedUids.map(async (uid: string) => {
      const userRef = admin.firestore().collection("users").doc(uid);
      await userRef.update({
        fridgeIds: admin.firestore.FieldValue.arrayRemove(fridgeId),
      });
      console.log(
        `[CloudFunction] Removed fridgeId ${fridgeId} from user ${uid} (kicked)`
      );
    });

    return Promise.all(promises);
  }
);

export const onFridgeDeleted = onDocumentDeleted(
  "fridges/{fridgeId}",
  async (event) => {
    const fridgeId = event.params.fridgeId;
    const before = event.data?.data() as { sharedWith?: string[], creatorId?: string };

    // 삭제 전 멤버 목록 (creator + sharedWith)
    const memberUids = new Set<string>();
    if (before?.creatorId) memberUids.add(before.creatorId);
    if (before?.sharedWith) before.sharedWith.forEach(uid => memberUids.add(uid));

    const promises = Array.from(memberUids).map(async (uid) => {
      const userRef = admin.firestore().collection("users").doc(uid);
      await userRef.update({
        fridgeIds: admin.firestore.FieldValue.arrayRemove(fridgeId),
      });
      console.log(`[CloudFunction] Removed fridgeId ${fridgeId} from user ${uid} (fridge deleted)`);
    });

    return Promise.all(promises);
  }
);
