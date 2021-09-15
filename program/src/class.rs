use solana_program::pubkey::Pubkey;
use solana_program::account_info::{AccountInfo, next_account_info};
use solana_program::entrypoint::ProgramResult;
use solana_program::log::sol_log;
use solana_program::program_error::ProgramError;
use solana_program::rent::Rent;

pub fn create_class(
    program_id: &Pubkey,
    // 0: class_block SIGNER WRITE
    accounts: &[AccountInfo],
    // 0..: name
    ins_data: &[u8],
) -> ProgramResult {
    if ins_data.len() == 0 {
        sol_log("Missing instruction arg 0.");
        return Err(ProgramError::InvalidInstructionData);
    }
    let mut acc_iter = accounts.iter();
    let block = next_account_info(&mut acc_iter)?;
    if block.owner != program_id {
        sol_log("Invalid owner on class block.");
        return Err(ProgramError::IllegalOwner);
    }
    if !block.is_signer {
        sol_log("Missing signature from class block.");
        return Err(ProgramError::MissingRequiredSignature);
    }
    if block.lamports() < Rent::default().minimum_balance(block.data_len()) {
        sol_log("Class block not rent-exempt.");
        return Err(ProgramError::AccountNotRentExempt);
    }
    if block.data_len() < 2048 {
        sol_log("Class block too small.");
        return Err(ProgramError::AccountDataTooSmall);
    }
    let mut data = block.data.borrow_mut();
    data[0..ins_data.len()].copy_from_slice(ins_data);
    data[ins_data.len()] = 0;
    Ok(())
}