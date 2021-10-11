use near_sdk::AccountId;
use near_sdk::collections::{UnorderedSet, Vector};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use crate::grade::Grade;

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Class{
    name: String,
    storage_id: u128,
    finalized: bool,
    owner: AccountId,
    members: UnorderedSet<u32>,
    grades: Vector<Grade>
}

impl Class{
    /* Getters */
    pub fn storage_id(&self) -> &u128 { &self.storage_id }
    pub fn owner(&self) -> &AccountId { &self.owner }
    pub fn name(&self) -> &String { &self.name }
    pub fn members(&self) -> &UnorderedSet<u32> { &self.members }
    pub fn member_count(&self) -> u64 { self.members.len() }
    pub fn grade_count(&self) -> u64 { self.grades.len() }
    pub fn finalized(&self) -> bool { self.finalized }

    pub fn new(name: &String, storage_id: u128, owner: AccountId, class_id: u128) -> Self{
        let mut mkey = b"clsm".to_vec(); mkey.extend_from_slice(&class_id.to_le_bytes());
        let mut gkey = b"clsg".to_vec(); gkey.extend_from_slice(&class_id.to_le_bytes());
        Self {
            name: name.clone(),
            storage_id,
            owner,
            finalized: false,
            members: UnorderedSet::new(mkey),
            grades: Vector::new(gkey)
        }
    }

    pub fn add_member(&mut self, member_id: &u32){
        self.members.insert(member_id);
    }

    pub fn finalize(&mut self){
        self.finalized = true;
    }

    pub fn add_grade(&mut self, name: &String, class_id: u128, values: &[(u32, u8)]){
        let g = Grade::new(name, class_id, self.grades.len() as u32, values);
        self.grades.push(&g);
    }

    pub fn get_grades(&self, member_id: &u32) -> Vec<(String, u64, Option<u8>)>{
        let mut v = vec![];
        for g in self.grades.iter(){
            v.push((g.name().clone(), *g.timestamp(), g.get_value(member_id)));
        }
        v
    }
    pub fn contains_member(&self, member_id: &u32) -> bool{
        self.members.contains(&member_id)
    }
}
