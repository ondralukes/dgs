use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::LookupMap;
use near_sdk::{env, near_bindgen, AccountId};

near_sdk::setup_alloc!();

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct State {
    storages: LookupMap<AccountId, IdentityStorage>
}

#[derive(BorshDeserialize, BorshSerialize)]
pub struct IdentityStorage{
    map: LookupMap<u32, String>,
    id_ctr: u32
}

impl Default for State{
    fn default() -> Self {
        Self{
            storages: LookupMap::new(b'r')
        }
    }
}

#[near_bindgen]
impl State {
    pub fn lookup(&self, id_acc: AccountId, id: u32) -> Option<String>{
        match self.storages.get(&id_acc){
            None => {
                env::log(format!("No storage for account {}", id_acc).as_bytes());
                None
            },
            Some(storage) => storage.lookup(id)
        }
    }

    fn load_or_create(&mut self, acc: &AccountId) -> IdentityStorage{
        match self.storages.get(&env::signer_account_id()){
            None => {
                env::log(format!("Creating storage for account {}", acc).as_bytes());
                IdentityStorage::new(&env::signer_account_id())
            },
            Some(storage) => {
                env::log(format!("Loaded storage for account {}", acc).as_bytes());
                storage
            }
        }
    }
    pub fn add(&mut self, name: String) -> u32{
        let acc = env::signer_account_id();
        let mut storage = self.load_or_create(&acc);
        let res = storage.add(&name);
        self.storages.insert(&acc, &storage);
        res
    }
}

impl IdentityStorage{
    pub fn new(acc: &AccountId) -> Self{
        Self{
            map: LookupMap::new(acc.as_bytes()),
            id_ctr: 0
        }
    }
    pub fn lookup(&self, id: u32) -> Option<String>{
        self.map.get(&id)
    }
    pub fn add(&mut self, name: &String) -> u32 {
        self.map.insert(&self.id_ctr, &name);
        env::log(format!("Inserted {} with id {}.", name, self.id_ctr).as_bytes());
        self.id_ctr += 1;
        return self.id_ctr-1;
    }
}