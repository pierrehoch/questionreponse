const {test} = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");
const {ageGroupAt, aggregateDemographics} = require("../lib/demographics.js");

test("age groups use full birthdays and include all boundaries", () => {
  const date = new Date("2026-10-30T12:00:00Z");
  for (const [age, expected] of [
    [0, "under18"], [17, "under18"], [18, "18-24"], [24, "18-24"],
    [25, "25-34"], [34, "25-34"], [35, "35-44"], [44, "35-44"],
    [45, "45-54"], [54, "45-54"], [55, "55-64"], [64, "55-64"],
    [65, "65plus"], [100, "65plus"],
  ]) {
    const birth = Timestamp.fromDate(new Date(Date.UTC(2026 - age, 9, 30)));
    assert.equal(ageGroupAt(birth, date), expected, `age ${age}`);
  }
  assert.equal(ageGroupAt(
    Timestamp.fromDate(new Date("2001-10-31T00:00:00Z")), date,
  ), "18-24");
  assert.equal(ageGroupAt(
    Timestamp.fromDate(new Date("2001-10-29T00:00:00Z")), date,
  ), "25-34");
  assert.equal(ageGroupAt(undefined, date), "unknown");
  assert.equal(ageGroupAt("2001-10-30", date), "unknown");
  assert.equal(ageGroupAt(Timestamp.fromDate(new Date("2027-01-01")), date), "unknown");
});

test("comparisons aggregate each response once in every dimension", () => {
  const result = aggregateDemographics([
    {type: "choice", choiceId: "a", country: "FR", sex: "female", ageGroup: "18-24"},
    {type: "choice", choiceId: "b", country: "FR", sex: "male", ageGroup: "25-34"},
    {type: "blank", country: "BE", sex: "other"},
    {type: "abstention", country: "BE", sex: "male", ageGroup: "65plus"},
    {type: "choice", choiceId: "a"},
  ]);
  for (const dimension of Object.values(result)) {
    assert.equal(Object.values(dimension)
      .reduce((sum, group) => sum + group.totalResponses, 0), 5);
  }
  assert.equal(result.country.FR.totalResponses, 2);
  assert.equal(result.country.FR.choiceCounts.a, 1);
  assert.equal(result.country.FR.choiceCounts.b, 1);
  assert.equal(result.country.BE.blankCount, 1);
  assert.equal(result.country.BE.abstentionCount, 1);
  assert.equal(result.age.unknown.totalResponses, 2);
  assert.equal(result.sex.unknown.totalResponses, 1);
  assert.equal(JSON.stringify(result).includes("birthDate"), false);
  assert.deepEqual(Object.keys(aggregateDemographics([]).country), []);
});
