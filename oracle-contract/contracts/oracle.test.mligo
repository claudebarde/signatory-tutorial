#include "./oracle.mligo"

let test =
    let _ = Test.reset_state 3n [] in
    let admin_address = Test.nth_bootstrap_account 1 in
    let user_address = Test.nth_bootstrap_account 2 in

    let addr, contract, _ = 
        let initial_storage =
        {
            valid_pairs     = Set.literal ["XTZ-USD", "BTC-USD", "ETH-USD"];
            exchange_rates  = Big_map.literal [
                ("XTZ-USD", 102n) ;
                ("BTC-USD", 1676942n) ;
                ("ETH-USD", 123434n)
            ];
            admin           = admin_address;
        }    
        in Test.originate_from_file "./oracle.mligo" "main" ["get_exchange_rate", "get_valid_pairs"] initial_storage 0tez in

    ()