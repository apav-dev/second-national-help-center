const dasha = require("@dasha.ai/sdk");

const main = async () => {
  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "Default";

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));
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
