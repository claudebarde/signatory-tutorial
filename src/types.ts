import type { BigMapAbstraction } from "@taquito/taquito";

interface GenericStorage {
  valid_pairs: Array<string>;
  exchange_rates: BigMapAbstraction;
  admin: string;
}

export type Storage = Readonly<GenericStorage>;
