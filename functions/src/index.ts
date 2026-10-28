import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  ResponseType,
  submitResponseTransaction,
} from "./response_service.js";

initializeApp();

const db = getFirestore();
const responseTypes = ["choice", "blank", "abstention"] as const;

interface SubmitResponseData {
  questionId?: unknown;
  type?: unknown;
  choiceId?: unknown;
}

interface FilteredStatisticsData {
  questionId?: unknown;
  country?: unknown;
  sex?: unknown;
}

export const submitResponse = onCall<SubmitResponseData>(
  {
    region: "europe-west9",
    enforceAppCheck: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "not_authorized");
    }

    const {questionId, type, choiceId} = validateRequest(request.data);
    const result = await submitResponseTransaction(db, userId, {
      questionId,
      type,
      choiceId,
    });
    logger.info("Response submitted", {questionId, userId, type});

    return {success: true, ...result};
  },
);

export const getFilteredStatistics = onCall<FilteredStatisticsData>(
  {
    region: "europe-west9",
    enforceAppCheck: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "not_authorized");
    }

    const {questionId, country, sex} = validateStatisticsRequest(request.data);
    const questionReference = db.collection("questions").doc(questionId);
    const responseReference = db
      .collection("users")
      .doc(userId)
      .collection("responses")
      .doc(questionId);
    const [question, participation] = await db.getAll(
      questionReference,
      responseReference,
    );

    if (!question.exists) {
      throw new HttpsError("not-found", "question_not_found");
    }
    if (question.get("status") !== "published") {
      throw new HttpsError("failed-precondition", "question_not_published");
    }
    if (!participation.exists) {
      throw new HttpsError(
        "permission-denied",
        "statistics_not_available",
      );
    }

    let query = db
      .collectionGroup("responses")
      .where("questionId", "==", questionId);
    if (country) {
      query = query.where("country", "==", country);
    }
    if (sex) {
      query = query.where("sex", "==", sex);
    }

    const responses = await query.get();
    const choiceCounts: Record<string, number> = {};
    let blankCount = 0;
    let abstentionCount = 0;

    for (const document of responses.docs) {
      const type = document.get("type");
      if (type === "choice") {
        const choiceId = document.get("choiceId");
        if (typeof choiceId === "string") {
          choiceCounts[choiceId] = (choiceCounts[choiceId] ?? 0) + 1;
        }
      } else if (type === "blank") {
        blankCount++;
      } else if (type === "abstention") {
        abstentionCount++;
      }
    }

    return {
      totalResponses: responses.size,
      choiceCounts,
      blankCount,
      abstentionCount,
      updatedAt: new Date().toISOString(),
    };
  },
);

export const publishScheduledQuestions = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "europe-west9",
    timeZone: "Europe/Paris",
  },
  async () => {
    const dueQuestions = await db
      .collection("questions")
      .where("status", "==", "scheduled")
      .where("scheduledAt", "<=", Timestamp.now())
      .limit(100)
      .get();

    await Promise.all(
      dueQuestions.docs.map(async (snapshot) => {
        await db.runTransaction(async (transaction) => {
          const current = await transaction.get(snapshot.ref);
          if (
            !current.exists ||
            current.get("status") !== "scheduled" ||
            !(current.get("scheduledAt") instanceof Timestamp) ||
            current.get("scheduledAt").toMillis() > Date.now()
          ) {
            return;
          }

          transaction.update(snapshot.ref, {
            status: "published",
            publishedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
        });
      }),
    );
    logger.info("Scheduled publication scan completed", {
      publishedCount: dueQuestions.size,
    });
  },
);

function validateRequest(data: SubmitResponseData): {
  questionId: string;
  type: ResponseType;
  choiceId: string | null;
} {
  const questionId = typeof data.questionId === "string" ?
    data.questionId.trim() :
    "";
  if (!questionId) {
    throw new HttpsError("invalid-argument", "question_not_found");
  }

  if (
    typeof data.type !== "string" ||
    !responseTypes.includes(data.type as ResponseType)
  ) {
    throw new HttpsError("invalid-argument", "invalid_response_type");
  }
  const type = data.type as ResponseType;
  const choiceId = typeof data.choiceId === "string" ?
    data.choiceId.trim() :
    null;

  if ((type === "choice" && !choiceId) || (type !== "choice" && choiceId)) {
    throw new HttpsError("invalid-argument", "invalid_choice");
  }

  return {questionId, type, choiceId};
}

function validateStatisticsRequest(data: FilteredStatisticsData): {
  questionId: string;
  country: string | null;
  sex: string | null;
} {
  const questionId = typeof data.questionId === "string" ?
    data.questionId.trim() :
    "";
  const country = typeof data.country === "string" &&
    data.country.trim() !== "" ?
    data.country.trim().toUpperCase() :
    null;
  const sex = typeof data.sex === "string" && data.sex.trim() !== "" ?
    data.sex.trim() :
    null;

  if (!questionId) {
    throw new HttpsError("invalid-argument", "question_not_found");
  }
  if (!country && !sex) {
    throw new HttpsError("invalid-argument", "filters_required");
  }
  if (country && !/^[A-Z]{2}$/.test(country)) {
    throw new HttpsError("invalid-argument", "invalid_country");
  }
  if (sex && !["male", "female", "other"].includes(sex)) {
    throw new HttpsError("invalid-argument", "invalid_sex");
  }

  return {questionId, country, sex};
}
