require("dotenv").config();

const { provideCore } = require("@yext/answers-core");
const core = provideCore({
  apiKey: process.env.ANSWERS_API_KEY,
  experienceKey: "firstfinancial-answers",
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

const main = async () => {
  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "Default";

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));

  app.setExternal("search", async (args, conv) => {
    const response = await core.universalSearch({ query: "branches near me" });
    console.log(response);

    return "Hello from Answers!";
  });

  await app.start();

  const conv = app.createConversation({
    phone: process.argv[2],
  });

  await conv.execute();

  await app.stop();
  app.dispose();
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
