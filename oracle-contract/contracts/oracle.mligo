type coins_pair = string
type coins_pair_value =
{
    exchange_rate   : nat;
    last_update     : timestamp;
}

type update =
{
    coins_pair      : coins_pair;
    exchange_rate   : nat;
}

type parameter =
| Update_prices of update list
| Add_coins_pair of update
| Remove_coins_pair of coins_pair
| Update_admin of address

type storage =
{
    valid_pairs     : coins_pair set;
    exchange_rates  : (coins_pair, coins_pair_value) big_map;
    admin           : address;
}

type return = operation list * storage

let update_prices (updates, s: update list * storage): operation list * storage = 
    List.fold
        (
            fun ((ops, s), update : (operation list * storage) * update) -> 
                if Set.mem update.coins_pair s.valid_pairs
                then
                    (Tezos.emit "%price_update" update) :: ops,
                    { 
                        s with 
                            exchange_rates = 
                                Big_map.update 
                                    update.coins_pair 
                                    (Some { exchange_rate = update.exchange_rate ; last_update = Tezos.get_now () }) 
                                    s.exchange_rates
                    }
                else
                    failwith "INVALID_COINS_PAIR"
        )
        updates
        ([], s)

let add_coins_pair (update, s: update * storage): storage =
    { 
        s with 
            valid_pairs = Set.add update.coins_pair s.valid_pairs ;
            exchange_rates = 
                Big_map.add 
                    update.coins_pair 
                    { exchange_rate = update.exchange_rate ; last_update = Tezos.get_now () } 
                    s.exchange_rates
    }

let remove_coins_pair (pair_to_remove, s: coins_pair * storage): storage = 
    { 
        s with 
            valid_pairs     = Set.remove pair_to_remove s.valid_pairs ;
            exchange_rates  = Big_map.remove pair_to_remove s.exchange_rates ;
    }

let update_admin (new_admin, s: address * storage): storage = 
    { s with admin = new_admin }

let main (p, s: parameter * storage): return =
    if Tezos.get_sender () = s.admin
    then
        match p with
        | Update_prices l -> update_prices (l, s)
        | Add_coins_pair c -> [], add_coins_pair (c, s)
        | Remove_coins_pair c -> [], remove_coins_pair (c, s)
        | Update_admin a -> [], update_admin (a, s)
    else
        failwith "NOT_AN_ADMIN"

[@view]
let get_exchange_rate (coins_pair, s: string * storage): coins_pair_value option =
    if Set.mem coins_pair s.valid_pairs
    then
        Big_map.find_opt coins_pair s.exchange_rates
    else
        (None: coins_pair_value option)

[@view]
let get_valid_pairs (_, s: unit * storage): coins_pair set = s.valid_pairs