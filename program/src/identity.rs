use crate::ensure_exempt;
use solana_program::account_info::{next_account_info, AccountInfo};
use solana_program::entrypoint::ProgramResult;
use solana_program::log::sol_log;
use solana_program::program_error::ProgramError;
use solana_program::pubkey::Pubkey;
use solana_program::rent::Rent;

trait IsZero {
    fn is_zero(&self) -> bool;
}

impl IsZero for [u8] {
    fn is_zero(&self) -> bool {
        let mut iter = self.iter();
        loop {
            match iter.next() {
                None => return true,
                Some(x) => {
                    if *x != 0 {
                        return false;
                    }
                }
            }
        }
    }
}

pub fn create_identity(
    program_id: &Pubkey,
    // 0: identity_block SIGNER WRITE
    // 1: identity_sub_block WRITE
    // 2..: identity_sub_block_cont WRITE
    accounts: &[AccountInfo],
    // 0: sub_block_index
    // 1..: UTF-8 encoded name
    ins_data: &[u8],
) -> ProgramResult {
    if ins_data.len() < 1 {
        sol_log("Missing instruction arg 0.");
        return Err(ProgramError::InvalidInstructionData);
    }
    let mut acc_iter = accounts.iter();
    let block = next_account_info(&mut acc_iter)?;
    if block.owner != program_id {
        sol_log("Invalid owner on identity block.");
        return Err(ProgramError::IllegalOwner);
    }
    if !block.is_signer {
        sol_log("Missing signature from identity block.");
        return Err(ProgramError::MissingRequiredSignature);
    }
    if block.data_len() < 8192 {
        sol_log("Identity block too small.");
        return Err(ProgramError::AccountDataTooSmall);
    }
    if block.lamports() < Rent::default().minimum_balance(block.data_len()) {
        sol_log("Identity block not rent-exempt.");
        return Err(ProgramError::AccountNotRentExempt);
    }

    let sub_block = next_account_info(&mut acc_iter)?;
    if sub_block.data_len() < 2048 {
        sol_log("Identity sub-block too small.");
        return Err(ProgramError::AccountDataTooSmall);
    }
    let sub_block_index = ins_data[0];
    let sub_block_ref = &mut block.data.borrow_mut()
        [(sub_block_index * 32) as usize..(sub_block_index * 32 + 32) as usize];
    let mut new = false;
    if sub_block_ref.is_zero() {
        sol_log("Attaching sub-block.");
        sub_block_ref.clone_from_slice(&sub_block.key.to_bytes());
        new = true;
    } else if sub_block_ref != &sub_block.key.to_bytes() {
        sol_log("Reference to sub-block not found.");
        return Err(ProgramError::InvalidAccountData);
    }

    write_to_sub_block_chain(&accounts[1..], &ins_data[1..], new)
}

fn write_to_sub_block_chain(
    accounts: &[AccountInfo],
    name: &[u8],
    is_new: bool,
) -> ProgramResult {
    let mut acc_iter = accounts.iter();
    let mut cur = acc_iter
        .next()
        .ok_or_else(|| ProgramError::InvalidArgument)?;
    let mut appended = None;
    if is_new {
        appended = Some(cur.key);
    }
    loop {
        match acc_iter.next() {
            None => {
                if !cur.data.borrow()[2016..].is_zero() {
                    sol_log("Missing identity sub-block reference in account list.");
                    return Err(ProgramError::InvalidArgument);
                }
                break;
            }
            Some(next) => {
                let brw = &mut cur.data.borrow_mut()[2016..];
                if brw.is_zero() {
                    ensure_exempt(next)?;
                    brw.copy_from_slice(&next.key.to_bytes());
                    sol_log("Identity sub-block appended.");
                    appended = Some(next.key);
                    break;
                }
                if brw != next.key.to_bytes() {
                    sol_log("Identity sub-block reference does not match account list.");
                    return Err(ProgramError::InvalidArgument);
                }
                cur = next;
            }
        }
    }
    let mut used_indexes = vec![false; 256];
    let iter = accounts.iter();
    for acc in iter {
        if Some(acc.key) == appended {
            continue;
        }
        let acc_data = &acc.data.borrow()[..2016];
        let mut data_iter = acc_data.iter();
        loop {
            match data_iter.next() {
                None => break,
                Some(x) => {
                    if used_indexes[*x as usize] {
                        if *x == 0 && data_iter.as_slice().is_zero() {
                            break;
                        }
                        sol_log(&format!(
                            "Identity sub-block corrupted. (double-index {})",
                            x
                        ));
                        return Err(ProgramError::InvalidAccountData);
                    }
                    used_indexes[*x as usize] = true;
                    loop {
                        match data_iter.next() {
                            None => {
                                sol_log("Identity sub-block corrupted. (unterminated-string)");
                                return Err(ProgramError::InvalidAccountData);
                            }
                            Some(x) => {
                                if *x == 0 {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    let mut found = false;
    let mut free_index = 0;
    for (index, used) in used_indexes.iter().enumerate() {
        if !used {
            free_index = index;
            found = true;
            break;
        }
    }
    if !found {
        sol_log("All indexes used in identity sub-block.");
        return Err(ProgramError::InvalidAccountData);
    }

    let mut i = 0;
    let iter = accounts.iter();
    for acc in iter {
        let data = &mut acc.data.borrow_mut()[..2016];
        if appended == Some(acc.key) {
            data[0] = free_index as u8;
            data[1..name.len() + 1].copy_from_slice(name);
            sol_log(&format!(
                "Assigned sub-block index {}, sub-block chain index {}, byte-offset 0",
                free_index, i
            ));
            return Ok(());
        }
        let mut offset = 0;
        loop {
            if offset + name.len() + 2 >= 2016 {
                break;
            }
            if data[offset] == 0 && data[offset..offset + name.len() + 2].is_zero() {
                data[offset] = free_index as u8;
                data[offset + 1..offset + name.len()+1].copy_from_slice(name);
                sol_log(&format!(
                    "Assigned sub-block index {}, sub-block chain index {}, byte-offset {}",
                    free_index, i, offset
                ));
                return Ok(());
            }
            while offset != 2016 && data[offset] != 0 {
                offset += 1;
            }
            offset += 1;
        }
        i += 1;
    }
    sol_log("No space left in identity sub-block.");
    return Err(ProgramError::InvalidAccountData);
}
