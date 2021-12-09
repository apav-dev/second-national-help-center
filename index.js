require("dotenv").config();
const { provideCore } = require("@yext/answers-core");

const answers = provideCore({
  apiKey: process.env.ANSWERS_API_KEY,
  experienceKey: "dasha",
  locale: "en",
  experienceVersion: "PRODUCTION",
  endpoints: {
    universalSearch:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/answers/query?someparam=blah",
    verticalSearch:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/answers/vertical/query",
    questionSubmission:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/createQuestion",
    status: "https://answersstatus.pagescdn.com",
    universalAutocomplete:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/answers/autocomplete",
    verticalAutocomplete:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/answers/vertical/autocomplete",
    filterSearch:
      "https://liveapi-sandbox.yext.com/v2/accounts/me/answers/filtersearch",
  },
});

const dasha = require("@dasha.ai/sdk");
const fs = require("fs");

const main = async () => {
  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "Default";

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));

  app.setExternal("lookForBranch", async (args, conv) => {
    const street_num = args.street_num;
    const street = args.street;
    const city = args.city;
    const state = args.state;
    const zip_code = args.zip_code;
    const locationQuery = `${street_num} ${street} ${city} ${state} ${zip_code}`;

    console.log(
      `street number: ${street_num} street: ${street} city: ${city} state: ${state} zip code: ${zip_code}`
    );

    const branchesResponse = await answers.verticalSearch({
      query: locationQuery,
      verticalKey: "locations",
      limit: 1,
    });

    const branchLocation =
      branchesResponse.verticalResults.results[0].rawData.address;

    return `So it looks like we have a location at ${branchLocation.line1}. Would you like me to make you an appointment?`;
  });

  await app.start();

  const conv = app.createConversation({
    phone: process.argv[2] ?? "",
  });

  if (conv.input.phone !== "chat") conv.on("transcription", console.log);

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  await conv.execute();

  await app.stop();
  app.dispose();
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
