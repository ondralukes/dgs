use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{LookupMap, UnorderedSet};
use near_sdk::{env, near_bindgen, AccountId};

near_sdk::setup_alloc!();

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct State {
    storage_id_ctr: u128,
    storages: LookupMap<u128, IdentityStorage>,
    // cls_id_ctr: u128,
    // classes: LookupMap<u128, Class>
}

#[derive(BorshDeserialize, BorshSerialize)]
pub struct IdentityStorage{
    map: LookupMap<u32, Person>,
    id_ctr: u32,
    owner: AccountId
}

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Person{
    name: String,
    classes: UnorderedSet<u128>
}

// #[derive(BorshDeserialize, BorshSerialize)]
// pub struct Class{
//     name: String,
//     identity: AccountId,
//     owner: AccountId,
//     members: UnorderedSet<u32>,
//     // grades: Vector<Grade>
// }

// #[derive(BorshDeserialize, BorshSerialize)]
// pub struct Grade{
//     desc: String,
//     values: UnorderedMap<u32, u8>
// }

impl Default for State{
    fn default() -> Self {
        Self{
            storage_id_ctr: 0,
            storages: LookupMap::new(b'i'),
            // cls_id_ctr: 0,
            // classes: LookupMap::new(b'c')
        }
    }
}

#[near_bindgen]
impl State {
    pub fn id_create(&mut self) -> u128{
        let storage = IdentityStorage::new(&env::signer_account_id());
        let id = self.storage_id_ctr;
        self.storage_id_ctr+=1;
        self.storages.insert(&id, &storage);
        id
    }

    pub fn id_add(&mut self, storage_id: u128, name: String) -> u32{
        match self.storages.get(&storage_id){
            None => {
                panic!("No such IdentityStorage!");
            }
            Some(mut storage) => {
                assert_eq!(storage.owner == env::signer_account_id(), "Only the owner can manage identity records.");
                let id = storage.add(storage_id, &name);
                self.storages.insert(&storage_id, &storage);
                id
            }
        }
    }

    pub fn id_lookup(&self, storage_id: u128, id: u32) -> Option<String>{
        match self.storages.get(&storage_id){
            None => {
                panic!("No such IdentityStorage!");
            }
            Some(storage) => {
                match storage.lookup(id){
                    None => None,
                    Some(p) => Some(p.name)
                }
            }
        }
    }
}

impl IdentityStorage{
    pub fn new(acc: &AccountId) -> Self{
        let mut key = b"idm".to_vec();
        key.extend_from_slice(acc.as_bytes());
        Self{
            map: LookupMap::new(key),
            id_ctr: 0,
            owner: acc.clone()
        }
    }
    pub fn lookup(&self, id: u32) -> Option<Person>{
        self.map.get(&id)
    }
    pub fn add(&mut self, storage_id: u128, name: &String) -> u32 {
        let id = self.id_ctr;
        self.id_ctr += 1;
        let person = Person::new(name, storage_id, id);
        self.map.insert(&id, &person);
        id
    }
}

impl Person{
    pub fn new(name: &String, storage_id: u128, id: u32) -> Self{
        let mut key = b"pcls".to_vec();
        key.extend_from_slice(&storage_id.to_le_bytes());
        key.extend_from_slice(&id.to_le_bytes());
        Self{
            name: name.clone(),
            classes: UnorderedSet::new(key)
        }
    }
}
//
// impl Class{
//     pub fn new(name: String, identity: AccountId, owner: AccountId, class_id: u128) -> Self{
//         let mut mkey = b"clsm".to_vec(); mkey.extend_from_slice(&class_id.to_le_bytes());
//         // let mut gkey = b"clsg".to_vec(); gkey.extend_from_slice(&class_id.to_le_bytes());
//         Self {
//             name,
//             identity,
//             owner,
//             members: UnorderedSet::new(mkey),
//             // grades: Vector::new(gkey)
//         }
//     }
// }