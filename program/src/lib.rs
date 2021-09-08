mod identity;

use crate::identity::create_identity;
use solana_program::account_info::AccountInfo;
use solana_program::entrypoint;
use solana_program::entrypoint::ProgramResult;
use solana_program::log::sol_log;
use solana_program::program_error::ProgramError;
use solana_program::pubkey::Pubkey;
use solana_program::rent::Rent;
use std::fmt::{Display, Formatter};

entrypoint!(main);

#[repr(u8)]
#[allow(dead_code)]
enum InstructionType {
    CreateIdentity = 0,
    Invalid = 255,
}

impl From<u8> for InstructionType {
    fn from(x: u8) -> Self {
        if x > 0 {
            return InstructionType::Invalid;
        }
        unsafe { std::mem::transmute(x) }
    }
}

impl Display for InstructionType {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            InstructionType::CreateIdentity => f.write_str("CreateIdentity"),
            InstructionType::Invalid => f.write_str("Invalid"),
        }
    }
}
fn main(program_id: &Pubkey, accounts: &[AccountInfo], ins_data: &[u8]) -> ProgramResult {
    if ins_data.len() == 0 {
        return Err(ProgramError::InvalidInstructionData);
    }
    let ins_type = ins_data[0].into();
    sol_log(&format!("Instruction type: {}", ins_type));
    match ins_type {
        InstructionType::CreateIdentity => create_identity(program_id, accounts, &ins_data[1..]),
        InstructionType::Invalid => Err(ProgramError::InvalidInstructionData),
    }
}

fn ensure_exempt(account: &AccountInfo) -> ProgramResult {
    let rent = Rent::default();
    let rent_needed = rent.minimum_balance(account.data_len());
    if account.lamports() < rent_needed {
        return Err(ProgramError::AccountNotRentExempt);
    }
    Ok(())
}
