import express from "express";
import axios from "axios";
import { TezosToolkit, MichelsonMap } from "@taquito/taquito";
import { updateOracle } from "./cronJob";
import oracleCode from "./oracle.json";
import type { Storage } from "./types";
import type BigNumber from "bignumber.js";

const app = express();
const port = 3456;
const signatoryPort = 6732;
const signatorySigner = "tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb";
const flextesaUrl = "http://localhost:20000";
let contractAddress = "";

app.get("/", (_, res) => {
  res.send("Hello Signatory!");
});

app.get("/originate-oracle", async (_, res) => {
  const Tezos = new TezosToolkit(flextesaUrl);
  try {
    // checks if the contract doesn't already exist
    const contract = await Tezos.contract.at(contractAddress);
    if (contract)
      throw `Contract already exists at address "${contractAddress}"`;

    // prepares the initial storage for the contract
    const initialStorage: Omit<Storage, "exchange_rates"> & {
      exchange_rates: MichelsonMap<
        string,
        { exchange_rate: BigNumber; last_update: string }
      >;
    } = {
      valid_pairs: ["BTC-USD", "ETH-USD", "XTZ-USD"],
      exchange_rates: new MichelsonMap(),
      admin: signatorySigner
    };
    // originates the contract
    const originationOp = await Tezos.contract.originate({
      code: oracleCode,
      storage: initialStorage
    });
    await originationOp.confirmation();
    contractAddress = originationOp.contractAddress || "";

    res.status(200).send({ contractAddress });
  } catch (error) {
    res.status(500).send(JSON.stringify(error));
  }
});

app.get("/signer-pk", async (_, res) => {
  try {
    const axiosRes = await axios.get(
      `http://localhost:${signatoryPort}/keys/${signatorySigner}`
    );
    if (axiosRes) {
      const { data } = axiosRes;
      if (data.hasOwnProperty("public_key")) {
        res.status(200).send({ signerPk: data.public_key });
      } else {
        throw "Signatory didn't return the signer's public key";
      }
    } else {
      throw "Error fetching signer's public key";
    }
  } catch (error) {
    res.status(500).send(error);
  }
});

updateOracle();

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
