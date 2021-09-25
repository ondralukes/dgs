use near_sdk::collections::UnorderedSet;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Person{
    name: String,
    classes: UnorderedSet<u128>
}

impl Person{
    /* Getters */
    pub fn name(&self) -> &String { &self.name }

    pub fn new(name: &String, storage_id: u128, id: u32) -> Self{
        let mut key = b"pcls".to_vec();
        key.extend_from_slice(&storage_id.to_le_bytes());
        key.extend_from_slice(&id.to_le_bytes());
        Self{
            name: name.clone(),
            classes: UnorderedSet::new(key)
        }
    }
    pub fn add_class(&mut self, class_id: &u128){
        self.classes.insert(class_id);
    }
    pub fn get_classes(&self) -> Vec<u128>{
        self.classes.to_vec()
    }
}
