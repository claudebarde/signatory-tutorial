import CronJob from "node-cron";
import CoinGecko from "coingecko-api";

export const updateOracle = () => {
    const CoinGeckoClient = new CoinGecko();

    // TODO: change the Cron job to every 5 minutes
  const scheduledJobFunction = CronJob.schedule("*/1 * * * *", async () => {
      const res = await CoinGeckoClient.simple.price({ ids: ["bitcoin", "ethereum", "tezos"], vs_currencies: "usd" });
      if (res.success && res.code === 200) {
          console.log(res.data)
      }
  });

  scheduledJobFunction.start();
}