use near_sdk::AccountId;
use near_sdk::collections::UnorderedSet;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Class{
    name: String,
    storage_id: u128,
    owner: AccountId,
    members: UnorderedSet<u32>,
    // grades: Vector<Grade>
}

impl Class{
    /* Getters */
    pub fn storage_id(&self) -> &u128 { &self.storage_id }
    pub fn owner(&self) -> &AccountId { &self.owner }

    pub fn new(name: &String, storage_id: u128, owner: AccountId, class_id: u128) -> Self{
        let mut mkey = b"clsm".to_vec(); mkey.extend_from_slice(&class_id.to_le_bytes());
        // let mut gkey = b"clsg".to_vec(); gkey.extend_from_slice(&class_id.to_le_bytes());
        Self {
            name: name.clone(),
            storage_id,
            owner,
            members: UnorderedSet::new(mkey),
            // grades: Vector::new(gkey)
        }
    }

    pub fn add_member(&mut self, member_id: &u32){
        self.members.insert(member_id);
    }
}
