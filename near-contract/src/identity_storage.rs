use near_sdk::AccountId;
use near_sdk::collections::LookupMap;
use crate::person::Person;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};

#[derive(BorshDeserialize, BorshSerialize)]
pub struct IdentityStorage{
    map: LookupMap<u32, Person>,
    id_ctr: u32,
    owner: AccountId
}

impl IdentityStorage{
    /* Getters */
    pub fn owner(&self) -> &AccountId { &self.owner }

    pub fn new(acc: &AccountId) -> Self{
        let mut key = b"idm".to_vec();
        key.extend_from_slice(acc.as_bytes());
        Self{
            map: LookupMap::new(key),
            id_ctr: 0,
            owner: acc.clone()
        }
    }
    pub fn lookup(&self, id: &u32) -> Option<Person>{
        self.map.get(id)
    }
    pub fn contains(&self, id: &u32) -> bool{
        self.map.contains_key(id)
    }
    pub fn add(&mut self, storage_id: u128, name: &String) -> u32 {
        let id = self.id_ctr;
        self.id_ctr += 1;
        let person = Person::new(name, storage_id, id);
        self.map.insert(&id, &person);
        id
    }
    pub fn update(&mut self, id: &u32, value: &Person){
        self.map.insert(id, value);
    }
}
