#include "./oracle.mligo"

let is_not_admin (oracle_address: address) (params: parameter): bool =
    match Test.transfer oracle_address (Test.compile_value params) 0tez with
    | Success _ -> false
    | Fail err ->
        (match err with
        | Rejected (msg, _) -> msg = Test.compile_value "NOT_AN_ADMIN"
        | _ -> false)

let test =
    let _ = Test.reset_state 3n [] in
    let admin_address = Test.nth_bootstrap_account 1 in
    let user_address = Test.nth_bootstrap_account 2 in

    let oracle_address, contract, _ = 
        let now = Tezos.get_now () in
        let initial_storage =
        {
            valid_pairs     = Set.literal ["XTZ-USD" ; "BTC-USD" ; "ETH-USD"];
            exchange_rates  = Big_map.literal [
                ("XTZ-USD", { exchange_rate = 102n ; last_update = now }) ;
                ("BTC-USD", { exchange_rate = 1676942n ; last_update = now }) ;
                ("ETH-USD", { exchange_rate = 123434n ; last_update = now })
            ];
            admin           = admin_address;
        } |> Test.eval
        in Test.originate_from_file "./oracle.mligo" "main" ["get_exchange_rate" ; "get_valid_pairs"] initial_storage 0tez 
    in
    let storage: storage = Test.get_storage_of_address oracle_address |> Test.decompile in
    let _ = assert (storage.admin = admin_address) in

    (*
        Tests %update_prices
    *)
    // should be impossible to send a transaction if not admin
    let _ = Test.set_source user_address in
    let valid_update_prices_params = Update_prices [
        { coins_pair = "BTC-USD" ; exchange_rate = 1500000n} ;
        { coins_pair = "ETH-USD" ; exchange_rate = 130000n}
    ] in
    let _ = assert (is_not_admin oracle_address valid_update_prices_params) in

    // should fail when an invalid pair of coins is passed
    let _ = Test.set_source admin_address in
    let wrong_pair_params = Update_prices [
        { coins_pair = "BTC-USD" ; exchange_rate = 1500000n } ;
        { coins_pair = "SOL-USD" ; exchange_rate = 5n }
    ] in
    let _ = 
        (match Test.transfer oracle_address (Test.compile_value wrong_pair_params) 0tez with
        | Success _ -> false
        | Fail err ->
            (match err with
            | Rejected (msg, _) -> msg = Test.compile_value "INVALID_COINS_PAIR:SOL-USD"
            | _ -> false))
        |> assert
    in

    // should update the exchange rates in the bigmap
    let prev_storage: storage = Test.get_storage_of_address oracle_address |> Test.decompile in
    let btc_exchange_rate, eth_exchange_rate: (nat option) * (nat option) =
        match (Big_map.find_opt "BTC-USD" storage.exchange_rates, Big_map.find_opt "ETH-USD" storage.exchange_rates) with
        | None, Some r -> None, Some r.exchange_rate
        | Some r, None -> Some r.exchange_rate, None
        | Some b, Some e -> Some b.exchange_rate, Some e.exchange_rate
        | _ -> None, None
    in
    let _ = 
        (match Test.transfer oracle_address (Test.compile_value valid_update_prices_params) 0tez with
        | Success _ -> true
        | Fail _ -> false)
        |> assert
    in
    let storage: storage = Test.get_storage_of_address oracle_address |> Test.decompile in
    let new_btc_exchange_rate, new_eth_exchange_rate: (nat option) * (nat option) =
        match (Big_map.find_opt "BTC-USD" storage.exchange_rates, Big_map.find_opt "ETH-USD" storage.exchange_rates) with
        | None, Some r -> None, Some r.exchange_rate
        | Some r, None -> Some r.exchange_rate, None
        | Some b, Some e -> Some b.exchange_rate, Some e.exchange_rate
        | _ -> None, None
    in
    // compares exchange rates
    let _ = 
        (match (btc_exchange_rate, new_btc_exchange_rate) with
        | Some btc, Some new_btc -> btc <> new_btc && btc = 1676942n && new_btc = 1500000n
        | _ -> false)
        |> assert
    in
    let _ = 
        (match (eth_exchange_rate, new_eth_exchange_rate) with
        | Some eth, Some new_eth -> eth <> new_eth && eth = 123434n && new_eth = 130000n
        | _ -> false)
        |> assert
    in

    (*
        Tests %add_coins_pair
    *)
    // should be impossible to send a transaction if not admin
    let _ = Test.set_source user_address in

    let _ = Test.set_source admin_address in

    (*
        Tests %remove_coins_pair
    *)
    // should be impossible to send a transaction if not admin
    let _ = Test.set_source user_address in

    let _ = Test.set_source admin_address in

    (*
        Tests %update_admin
    *)
    // should be impossible to send a transaction if not admin
    let _ = Test.set_source user_address in

    let _ = Test.set_source admin_address in

    ()