import {
  DocumentSnapshot,
  Firestore,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

export type ResponseType = "choice" | "blank" | "abstention";

export interface SubmitResponseInput {
  questionId: string;
  type: ResponseType;
  choiceId: string | null;
}

export interface SubmittedResponse {
  questionId: string;
  type: ResponseType;
  choiceId: string | null;
  country: string;
  sex: string;
  createdAt: string;
}

export interface ResponseStatistics {
  totalResponses: number;
  choiceCounts: Record<string, number>;
  blankCount: number;
  abstentionCount: number;
  updatedAt: string;
}

export interface SubmitResponseResult {
  response: SubmittedResponse;
  statistics: ResponseStatistics;
}

/**
 * Creates the user's response and updates the question counters.
 *
 * The committed response and the resulting statistics are returned so the
 * client can display results immediately instead of waiting for its
 * Firestore listeners to catch up.
 */
export async function submitResponseTransaction(
  db: Firestore,
  userId: string,
  input: SubmitResponseInput,
): Promise<SubmitResponseResult> {
  const {questionId, type, choiceId} = input;
  const questionReference = db.collection("questions").doc(questionId);
  const choiceReference = choiceId ?
    questionReference.collection("choices").doc(choiceId) :
    null;
  const profileReference = db.collection("users").doc(userId);
  const responseReference = profileReference
    .collection("responses")
    .doc(questionId);
  const statsReference = questionReference.collection("stats").doc("summary");

  await db.runTransaction(async (transaction) => {
    const [question, profile, existingResponse, choice] = await Promise.all([
      transaction.get(questionReference),
      transaction.get(profileReference),
      transaction.get(responseReference),
      choiceReference ? transaction.get(choiceReference) : null,
    ]);

    if (!question.exists) {
      throw new HttpsError("not-found", "question_not_found");
    }
    if (question.get("status") !== "published") {
      throw new HttpsError("failed-precondition", "question_not_published");
    }
    if (type === "blank" && question.get("allowBlank") !== true) {
      throw new HttpsError("failed-precondition", "response_type_not_allowed");
    }
    if (type === "abstention" && question.get("allowAbstention") !== true) {
      throw new HttpsError("failed-precondition", "response_type_not_allowed");
    }
    if (!profile.exists) {
      throw new HttpsError("failed-precondition", "profile_required");
    }
    if (existingResponse.exists) {
      throw new HttpsError("already-exists", "already_answered");
    }
    if (choiceReference && !choice?.exists) {
      throw new HttpsError("invalid-argument", "invalid_choice");
    }

    transaction.create(responseReference, {
      questionId,
      type,
      ...(choiceId ? {choiceId} : {}),
      country: profile.get("country"),
      sex: profile.get("sex"),
      createdAt: FieldValue.serverTimestamp(),
    });

    transaction.set(statsReference, {
      totalResponses: FieldValue.increment(1),
      choiceCounts: type === "choice" && choiceId ?
        {[choiceId]: FieldValue.increment(1)} :
        {},
      blankCount: FieldValue.increment(type === "blank" ? 1 : 0),
      abstentionCount: FieldValue.increment(type === "abstention" ? 1 : 0),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  const [response, statistics] = await db.getAll(
    responseReference,
    statsReference,
  );
  return {
    response: {
      questionId,
      type,
      choiceId,
      country: response.get("country"),
      sex: response.get("sex"),
      createdAt: isoDate(response, "createdAt"),
    },
    statistics: {
      totalResponses: statistics.get("totalResponses") ?? 0,
      choiceCounts: statistics.get("choiceCounts") ?? {},
      blankCount: statistics.get("blankCount") ?? 0,
      abstentionCount: statistics.get("abstentionCount") ?? 0,
      updatedAt: isoDate(statistics, "updatedAt"),
    },
  };
}

function isoDate(snapshot: DocumentSnapshot, field: string): string {
  const value = snapshot.get(field);
  const date = value instanceof Timestamp ? value.toDate() : new Date();
  return date.toISOString();
}
