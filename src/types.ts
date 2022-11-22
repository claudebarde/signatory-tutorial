import type { BigMapAbstraction } from "@taquito/taquito";

export interface Storage {
  valid_pairs: Array<string>;
  exchange_rates: BigMapAbstraction;
  admin: string;
}
