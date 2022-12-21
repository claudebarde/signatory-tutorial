import CronJob from "node-cron";
import CoinGecko from "coingecko-api";
import { TezosToolkit } from "@taquito/taquito";
import { RemoteSigner } from "@taquito/remote-signer";
import { flextesaUrl, signatorySigner, signatoryPort } from "./config";

const availableCoins = ["bitcoin", "ethereum", "tezos"];
const coinToCoinpair = (coin: string): string => {
  switch (coin) {
    case "bitcoin":
      return "BTC-USD";
    case "ethereum":
      return "ETH-USD";
    case "tezos":
      return "XTZ-USD";
    default:
      return "unknown";
  }
};

export const updateOracle = async (contractAddress: string) => {
  const Tezos = new TezosToolkit(flextesaUrl);
  const signer = new RemoteSigner(
    signatorySigner,
    `http://localhost:${signatoryPort}`
  );
  Tezos.setSignerProvider(signer);
  const contract = await Tezos.contract.at(contractAddress);
  const CoinGeckoClient = new CoinGecko();

  // NOTE: cron job set to 1 minute for demonstration purposes
  const scheduledJobFunction = CronJob.schedule("*/1 * * * *", async () => {
    const res = await CoinGeckoClient.simple.price({
      ids: availableCoins,
      vs_currencies: "usd"
    });
    if (res.success && res.code === 200) {
      // sends a transaction to update the oracle
      try {
        const op = await contract.methods
          .update_prices(
            availableCoins
              .map(coin => {
                if (res.data.hasOwnProperty(coin)) {
                  const price = res.data[coin].usd;
                  if (!isNaN(price)) {
                    return {
                      coins_pair: coinToCoinpair(coin),
                      exchange_rate: Math.floor(price * 10 ** 6)
                    };
                  } else {
                    return undefined;
                  }
                } else {
                  return undefined;
                }
              })
              .filter(el => el)
              .filter(el => el?.coins_pair === "unknown")
          )
          .send();
        await op.confirmation();
        console.log("Update prices confirmed!");
      } catch (error) {
        console.log("Unable to update prices '-_-");
        console.error(error);
      }
    }
  });

  scheduledJobFunction.start();
};
