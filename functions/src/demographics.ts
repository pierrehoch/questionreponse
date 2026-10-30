import {Timestamp} from "firebase-admin/firestore";

export const ageGroups = [
  "under18", "18-24", "25-34", "35-44", "45-54", "55-64", "65plus",
] as const;

export function ageGroupAt(birthDate: unknown, date: Date): string {
  if (!(birthDate instanceof Timestamp)) return "unknown";
  const birth = birthDate.toDate();
  if (birth > date || birth.getUTCFullYear() < 1900) return "unknown";
  let age = date.getUTCFullYear() - birth.getUTCFullYear();
  if (date.getUTCMonth() < birth.getUTCMonth() ||
      (date.getUTCMonth() === birth.getUTCMonth() &&
       date.getUTCDate() < birth.getUTCDate())) {
    age--;
  }
  if (age < 18) return "under18";
  if (age < 25) return "18-24";
  if (age < 35) return "25-34";
  if (age < 45) return "35-44";
  if (age < 55) return "45-54";
  if (age < 65) return "55-64";
  return "65plus";
}

interface Counts {
  totalResponses: number;
  choiceCounts: Record<string, number>;
  blankCount: number;
  abstentionCount: number;
}

export function aggregateDemographics(
  responses: Record<string, unknown>[],
): Record<string, Record<string, Counts>> {
  const result: Record<string, Record<string, Counts>> = {
    country: Object.create(null),
    sex: Object.create(null),
    age: Object.create(null),
  };
  for (const response of responses) {
    const groups = {
      country: typeof response.country === "string" &&
        /^[A-Z]{2}$/.test(response.country) ? response.country : "unknown",
      sex: typeof response.sex === "string" &&
        ["male", "female", "other"].includes(response.sex) ?
        response.sex : "unknown",
      age: typeof response.ageGroup === "string" &&
        (ageGroups as readonly string[]).includes(response.ageGroup) ?
        response.ageGroup : "unknown",
    };
    for (const [dimension, key] of Object.entries(groups)) {
      const counts = result[dimension][key] ??= {
        totalResponses: 0,
        choiceCounts: Object.create(null),
        blankCount: 0,
        abstentionCount: 0,
      };
      counts.totalResponses++;
      if (response.type === "choice" && typeof response.choiceId === "string") {
        counts.choiceCounts[response.choiceId] =
          (counts.choiceCounts[response.choiceId] ?? 0) + 1;
      } else if (response.type === "blank") {
        counts.blankCount++;
      } else if (response.type === "abstention") {
        counts.abstentionCount++;
      }
    }
  }
  return result;
}
