const fs = require("node:fs");
const path = require("node:path");
const {after, before, beforeEach, test} = require("node:test");
const assert = require("node:assert/strict");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  doc,
  addDoc,
  deleteDoc,
  getDoc,
  getDocs,
  query,
  orderBy,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require("firebase/firestore");
const {
  getBytes,
  ref,
  uploadBytes,
} = require("firebase/storage");
const {deleteApp, initializeApp} = require("firebase-admin/app");
const {
  FieldValue,
  getFirestore,
} = require("firebase-admin/firestore");
const {
  submitResponseTransaction,
} = require("../lib/response_service.js");

const projectId = "demo-question-reponse";
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../storage.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const timestamp = serverTimestamp();
    await setDoc(doc(db, "questions/published"), {
      text: "Question publiée ?",
      infoText: null,
      status: "published",
      createdAt: timestamp,
      updatedAt: timestamp,
      publishedAt: timestamp,
      createdBy: "admin",
      allowBlank: false,
      allowAbstention: false,
      chartType: "donut",
      icon: null,
    });
    await setDoc(doc(db, "questions/published/choices/yes"), {
      text: "Oui",
      position: 0,
    });
    await setDoc(doc(db, "questions/pending"), {
      text: "Question en attente ?",
      infoText: null,
      status: "pending",
      createdAt: timestamp,
      updatedAt: timestamp,
      publishedAt: null,
      scheduledAt: null,
      createdBy: "admin",
      allowBlank: false,
      allowAbstention: false,
      chartType: "donut",
      icon: null,
    });
    await setDoc(doc(db, "users/user-one"), {
      username: "user_one",
      normalizedUsername: "user_one",
      email: "one@example.com",
      photoUrl: null,
      country: "FR",
      sex: "other",
      createdAt: timestamp,
      updatedAt: timestamp,
    });
    await setDoc(doc(db, "questions/published/stats/summary"), {
      totalResponses: 1,
      choiceCounts: {yes: 1},
      blankCount: 0,
      abstentionCount: 0,
      updatedAt: timestamp,
    });
  });
});

after(async () => {
  await testEnvironment.cleanup();
});

test("published questions are readable but drafts require admin", async () => {
  const userDb = testEnvironment
    .authenticatedContext("user-one")
    .firestore();
  const adminDb = testEnvironment
    .authenticatedContext("admin", {admin: true})
    .firestore();

  await assertSucceeds(getDoc(doc(userDb, "questions/published")));
  await assertFails(getDoc(doc(userDb, "questions/pending")));
  await assertSucceeds(getDoc(doc(adminDb, "questions/pending")));
});

test("clients cannot write responses and statistics require participation", async () => {
  const userDb = testEnvironment
    .authenticatedContext("user-one")
    .firestore();

  await assertFails(setDoc(doc(userDb, "users/user-one/responses/published"), {
    questionId: "published",
    type: "choice",
    choiceId: "yes",
  }));
  await assertFails(
    getDoc(doc(userDb, "questions/published/stats/summary")),
  );

  await testEnvironment.withSecurityRulesDisabled((context) =>
    setDoc(
      doc(context.firestore(), "users/user-one/responses/published"),
      {
        questionId: "published",
        type: "choice",
        choiceId: "yes",
        country: "FR",
        sex: "other",
        createdAt: serverTimestamp(),
      },
    ),
  );
  await assertSucceeds(
    getDoc(doc(userDb, "questions/published/stats/summary")),
  );
});

test("admin can create drafts but cannot mutate published questions", async () => {
  const adminDb = testEnvironment
    .authenticatedContext("admin", {admin: true})
    .firestore();

  const draft = {
    text: "Nouvelle question ?",
    infoText: null,
    status: "pending",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    createdBy: "admin",
    scheduledAt: null,
    publishedAt: null,
    allowBlank: true,
    allowAbstention: false,
    chartType: "podium",
    icon: "vote",
  };
  await assertSucceeds(setDoc(doc(adminDb, "questions/new-draft"), draft));
  await assertFails(setDoc(doc(adminDb, "questions/bad-chart"), {
    ...draft,
    chartType: "pie",
  }));
  await assertFails(setDoc(doc(adminDb, "questions/bad-icon"), {
    ...draft,
    icon: "Not Valid!",
  }));
  await assertFails(setDoc(doc(adminDb, "questions/missing-flags"), {
    text: draft.text,
    infoText: null,
    status: "pending",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    createdBy: "admin",
    scheduledAt: null,
    publishedAt: null,
  }));
  await assertSucceeds(setDoc(
    doc(collection(adminDb, "questions/new-draft/choices")),
    {text: "Oui", position: 0},
  ));
  await assertFails(updateDoc(doc(adminDb, "questions/published"), {
    text: "Tentative de modification",
    updatedAt: serverTimestamp(),
  }));
});

test("comments are reserved to participants and bound to their real vote", async () => {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "users/user-one/responses/published"),
      {
        questionId: "published",
        type: "choice",
        choiceId: "yes",
        country: "FR",
        sex: "other",
        createdAt: serverTimestamp(),
      },
    );
  });
  const participantDb = testEnvironment
    .authenticatedContext("user-one")
    .firestore();
  const strangerDb = testEnvironment
    .authenticatedContext("user-two")
    .firestore();
  const adminDb = testEnvironment
    .authenticatedContext("admin", {admin: true})
    .firestore();
  const comments = (db) => collection(db, "questions/published/comments");
  const valid = () => ({
    userId: "user-one",
    username: "user_one",
    vote: "yes",
    text: "Mon avis sur la question",
    createdAt: serverTimestamp(),
  });

  const created = await assertSucceeds(addDoc(comments(participantDb), valid()));
  await assertSucceeds(getDocs(query(comments(participantDb), orderBy("createdAt"))));
  await assertSucceeds(getDocs(comments(adminDb)));
  await assertFails(getDocs(comments(strangerDb)));
  await assertFails(addDoc(comments(strangerDb), {...valid(), userId: "user-two"}));

  await assertFails(addDoc(comments(participantDb), {...valid(), vote: "no"}));
  await assertFails(addDoc(comments(participantDb), {...valid(), username: "imposteur"}));
  await assertFails(addDoc(comments(participantDb), {...valid(), userId: "user-two"}));
  await assertFails(addDoc(comments(participantDb), {...valid(), text: "   "}));
  await assertFails(addDoc(comments(participantDb), {...valid(), text: "x".repeat(501)}));
  await assertFails(addDoc(comments(participantDb), {...valid(), extra: true}));
  await assertFails(addDoc(comments(participantDb), {
    ...valid(),
    createdAt: new Date("2020-01-01"),
  }));
  await assertFails(updateDoc(created, {text: "modifié"}));

  await assertFails(deleteDoc(doc(strangerDb, created.path)));
  await assertSucceeds(deleteDoc(doc(participantDb, created.path)));
  const second = await assertSucceeds(addDoc(comments(participantDb), valid()));
  await assertSucceeds(deleteDoc(doc(adminDb, second.path)));
});

test("profile photos are owner-only writes with bounded image content", async () => {
  const ownerStorage = testEnvironment
    .authenticatedContext("user-one")
    .storage();
  const otherStorage = testEnvironment
    .authenticatedContext("user-two")
    .storage();
  const photo = ref(ownerStorage, "users/user-one/profile.jpg");
  const bytes = new Uint8Array([0xff, 0xd8, 0xff]);

  await assertSucceeds(uploadBytes(photo, bytes, {contentType: "image/jpeg"}));
  await assertSucceeds(getBytes(photo));
  await assertFails(uploadBytes(
    ref(otherStorage, "users/user-one/profile.jpg"),
    bytes,
    {contentType: "image/jpeg"},
  ));
  await assertFails(uploadBytes(
    ref(ownerStorage, "users/user-one/profile.jpg"),
    bytes,
    {contentType: "text/plain"},
  ));
});

test("concurrent submissions create exactly one immutable response", async () => {
  await testEnvironment.clearFirestore();
  const app = initializeApp({projectId}, `concurrency-${Date.now()}`);
  const db = getFirestore(app);
  await db.collection("questions").doc("question").set({
    status: "published",
  });
  await db
    .collection("questions")
    .doc("question")
    .collection("choices")
    .doc("yes")
    .set({text: "Oui", position: 0});
  await db.collection("users").doc("user").set({
    country: "FR",
    sex: "other",
  });

  const input = {
    questionId: "question",
    type: "choice",
    choiceId: "yes",
  };
  const results = await Promise.allSettled([
    submitResponseTransaction(db, "user", input),
    submitResponseTransaction(db, "user", input),
  ]);

  assert.equal(
    results.filter((result) => result.status === "fulfilled").length,
    1,
  );
  assert.equal(
    results.filter((result) => result.status === "rejected").length,
    1,
  );
  const [fulfilled] = results.filter(
    (result) => result.status === "fulfilled",
  );
  assert.equal(fulfilled.value.response.questionId, "question");
  assert.equal(fulfilled.value.response.choiceId, "yes");
  assert.equal(fulfilled.value.response.country, "FR");
  assert.equal(fulfilled.value.response.sex, "other");
  assert.ok(Date.parse(fulfilled.value.response.createdAt) > 0);
  assert.deepEqual(fulfilled.value.statistics, {
    totalResponses: 1,
    choiceCounts: {yes: 1},
    blankCount: 0,
    abstentionCount: 0,
    updatedAt: fulfilled.value.statistics.updatedAt,
  });
  assert.ok(Date.parse(fulfilled.value.statistics.updatedAt) > 0);
  const response = await db
    .collection("users/user/responses")
    .doc("question")
    .get();
  const statistics = await db
    .collection("questions/question/stats")
    .doc("summary")
    .get();
  assert.equal(response.exists, true);
  assert.equal(response.get("choiceId"), "yes");
  assert.equal(statistics.get("totalResponses"), 1);
  assert.equal(statistics.get("choiceCounts.yes"), 1);
  assert.equal(statistics.get("blankCount"), 0);
  assert.equal(statistics.get("abstentionCount"), 0);

  await db.recursiveDelete(db.collection("questions").doc("question"));
  await db.recursiveDelete(db.collection("users").doc("user"));
  await deleteApp(app);
});

test("blank votes and abstentions require the question to allow them", async () => {
  await testEnvironment.clearFirestore();
  const app = initializeApp({projectId}, `optional-${Date.now()}`);
  const db = getFirestore(app);
  await db.collection("questions").doc("strict").set({
    status: "published",
    allowBlank: false,
    allowAbstention: false,
  });
  await db.collection("questions").doc("open").set({
    status: "published",
    allowBlank: true,
    allowAbstention: true,
  });
  await db.collection("users").doc("user").set({
    country: "FR",
    sex: "other",
  });

  for (const type of ["blank", "abstention"]) {
    await assert.rejects(
      submitResponseTransaction(db, "user", {questionId: "strict", type}),
      (error) => error.code === "failed-precondition" &&
        error.message.includes("response_type_not_allowed"),
    );
  }
  const strictResponse = await db
    .collection("users/user/responses")
    .doc("strict")
    .get();
  assert.equal(strictResponse.exists, false);

  const result = await submitResponseTransaction(db, "user", {
    questionId: "open",
    type: "blank",
  });
  assert.equal(result.response.type, "blank");
  assert.equal(result.statistics.blankCount, 1);

  await db.recursiveDelete(db.collection("questions").doc("strict"));
  await db.recursiveDelete(db.collection("questions").doc("open"));
  await db.recursiveDelete(db.collection("users").doc("user"));
  await deleteApp(app);
});
