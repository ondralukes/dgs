use near_sdk::{env, near_bindgen};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::LookupMap;

use class::Class;
use identity_storage::IdentityStorage;

mod identity_storage;
mod person;
mod class;
mod grade;

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
                if cls.finalized(){
                    panic!("Cannot modify finalized class!");
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
                self.classes.insert(&class_id, &cls);
            }
        }
    }

    pub fn cls_get_info(&self, class_id: u128) -> (String, u128, bool, u64, u64){
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(cls) => (
                cls.name().clone(), *cls.storage_id(), cls.finalized(), cls.member_count(), cls.grade_count()
            )
        }
    }

    pub fn cls_get_members(&self, class_id: u128) -> Vec<(u32, String)>{
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(cls) => {
                match self.storages.get(cls.storage_id()){
                    None => panic!("Class references non-existent IdentityStorage!"),
                    Some(storage) => {
                        let mut v = vec![];
                        for id in cls.members().iter(){
                            match storage.lookup(&id){
                                None => panic!("Memeber not found in IdentityStorage!"),
                                Some(name) => {
                                    v.push((id, name.name().clone()));
                                }
                            }
                        }
                        v
                    }
                }
            }
        }
    }

    pub fn cls_add_grade(&mut self, class_id: u128, name: String, values: Vec<(u32, u8)>){
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(mut cls) => {
                if cls.owner() != &env::signer_account_id() {
                    panic!("Only class owner can add grades!");
                }
                if cls.finalized(){
                    panic!("Cannot modify finalized class!");
                }
                for (m, _) in &values {
                    if !cls.contains_member(&m){
                        panic!("Referenced person is not a member.");
                    }
                }
                cls.add_grade(&name, class_id, &values);
                self.classes.insert(&class_id, &cls);
            }
        }
    }

    pub fn cls_get_grades(&self, class_id: u128, member_id: u32) -> Vec<(String, u64, Option<u8>)>{
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(cls) => {
                cls.get_grades(&member_id)
            }
        }
    }

    pub fn cls_finalize(&mut self, class_id: u128) {
        match self.classes.get(&class_id){
            None => panic!("No such Class!"),
            Some(mut cls) => {
                if cls.owner() != &env::signer_account_id() {
                    panic!("Only owner can finalize class!");
                }
                cls.finalize();
                self.classes.insert(&class_id, &cls);
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
