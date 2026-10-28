import {applicationDefault, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

initializeApp({
  credential: applicationDefault(),
  projectId: "question-reponse-app",
});

async function main(): Promise<void> {
  const identifier = process.argv[2]?.trim();
  if (!identifier) {
    throw new Error("Usage: npm run set-admin -- <email-or-uid>");
  }

  const auth = getAuth();
  const user = identifier.includes("@") ?
    await auth.getUserByEmail(identifier) :
    await auth.getUser(identifier);
  await auth.setCustomUserClaims(user.uid, {
    ...user.customClaims,
    admin: true,
  });
  console.log(`Admin claim granted to ${user.email ?? user.uid}.`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
