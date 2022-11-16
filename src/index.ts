import express from "express";
import axios from "axios";
import { updateOracle } from "./cronJob";

const app = express()
const port = 3456
const signatoryPort = 6732;
const signatorySigner = "tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb";

app.get('/', (req, res) => {
  res.send('Hello Signatory!')
});

app.get('/signer-pk', async (req, res) => {
  try {
    const axiosRes = await axios.get(`http://localhost:${signatoryPort}/keys/${signatorySigner}`);
    if (axiosRes) {
      const { data } = axiosRes;
      if (data.hasOwnProperty("public_key")) {
        res.status(200).send({signerPk: data.public_key});
      } else {
        throw "Signatory didn't return the signer's public key"
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
  console.log(`Server listening on port ${port}`)
})