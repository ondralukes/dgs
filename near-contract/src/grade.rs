use near_sdk::collections::UnorderedMap;
use near_sdk::borsh::{self, BorshSerialize, BorshDeserialize};
use near_sdk::env;

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Grade{
    name: String,
    // milliseconds
    timestamp: u64,
    values: UnorderedMap<u32, u8>
}

impl Grade{
    /* Getters */
    pub fn name(&self) -> &String { &self.name }
    pub fn timestamp(&self) -> &u64 { &self.timestamp }

    pub fn new(name: &String, class_id: u128, grade_id: u32, values: &[(u32, u8)]) -> Self{
        let mut key = b"gv".to_vec();
        key.extend_from_slice(&class_id.to_le_bytes());
        key.extend_from_slice(&grade_id.to_le_bytes());
        let mut map = UnorderedMap::new(key);
        for (member, val) in values {
            map.insert(member, val);
        }
        Self {
            name: name.clone(),
            timestamp: env::block_timestamp()/1000000,
            values: map
        }
    }
    pub fn get_value(&self, member_id: &u32) -> Option<u8>{
        self.values.get(member_id)
    }
}