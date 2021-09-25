use near_sdk::{env, near_bindgen};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::LookupMap;

use class::Class;
use identity_storage::IdentityStorage;
use crate::person::Person;

mod identity_storage;
mod person;
mod class;

near_sdk::setup_alloc!();

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct State {
    storage_id_ctr: u128,
    storages: LookupMap<u128, IdentityStorage>,
    cls_id_ctr: u128,
    classes: LookupMap<u128, Class>
}

impl Default for State{
    fn default() -> Self {
        Self{
            storage_id_ctr: 0,
            storages: LookupMap::new(b'i'),
            cls_id_ctr: 0,
            classes: LookupMap::new(b'c')
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
                assert_eq!(storage.owner(), &env::signer_account_id(), "Only the owner can manage identity records.");
                let id = storage.add(storage_id, &name);
                // IdentityStorage::id_ctr was modified
                self.storages.insert(&storage_id, &storage);
                id
            }
        }
    }

    pub fn id_lookup(&self, storage_id: u128, id: u32) -> Option<String>{
        match self.storages.get(&storage_id){
            None => panic!("No such IdentityStorage!"),
            Some(storage) => {
                match storage.lookup(&id){
                    None => None,
                    Some(p) => Some(p.name().clone())
                }
            }
        }
    }

    pub fn cls_create(&mut self, storage_id: u128, name: String) -> u128{
        if !self.storages.contains_key(&storage_id) {
            panic!("No such IdentityStorage!");
        }
        let id = self.cls_id_ctr;
        self.cls_id_ctr += 1;
        let cls = Class::new(&name, storage_id, env::signer_account_id(), id);
        self.classes.insert(&id, &cls);
        id
    }

    pub fn cls_add_member(&mut self, class_id: u128, member_id: u32) {
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(mut cls) => {
                if cls.owner() != &env::signer_account_id() {
                    panic!("Only class owner can add members!");
                }
                match self.storages.get(cls.storage_id()){
                    None => panic!("Class references non-existent IdentityStorage!"),
                    Some(mut storage) => {
                        match storage.lookup(&member_id){
                            None => panic!("Memeber not found in IdentityStorage!"),
                            Some(mut person) => {
                                person.add_class(&class_id);
                                storage.update(&member_id, &person);
                            }
                        }
                    }
                }
                cls.add_member(&member_id);
            }
        }
    }

    pub fn p_get_classes(&self, storage_id: u128, id: u32) -> Vec<u128>{
        match self.storages.get(&storage_id){
            None => panic!("No such IdentityStorage!"),
            Some(storage) => {
                match storage.lookup(&id){
                    None => panic!("No such Person!"),
                    Some(person) => person.get_classes()
                }
            }
        }
    }
}
