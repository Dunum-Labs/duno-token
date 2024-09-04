////////////////////////////
//  2024 by Dunum Labs.   //
////////////////////////////

module Std::Duno {
	use std::signer;
	use std::string;
	use aptos_framework::coin;
	use aptos_framework::coin::{BurnCapability, FreezeCapability, MintCapability};

	// Duno token struct
	struct Duno has key {
		name: string::String,
		symbol: string::String,
		max_supply: u64,
		total_supply: u64,
		admin: address,
	}

	// Duno token capabilities
	struct DunoCapabilities has key {
		mint_cap: MintCapability<Duno>,
		burn_cap: BurnCapability<Duno>,
		freeze_cap: FreezeCapability<Duno>
	}

	// Checks if the account is the admin
	public fun check_admin(account: &signer) acquires Duno {
		let duno = borrow_global<Duno>(@Std);
		assert!(signer::address_of(account) == duno.admin, 104);
	}

	// Initializes the Duno token with predefined values
	public entry fun initialize(account: &signer) {
		
		if (exists<Duno>(@Std))
			abort 101;

		let admin = signer::address_of(account);
		let name = string::utf8(b"Duno");
		let symbol = string::utf8(b"DNO");
		let max_supply = 100_000_000;

		let duno = Duno {
			name: name,
			symbol: symbol,
			max_supply: max_supply,
			total_supply: 0,
			admin: admin,
		};

		let (burn_cap, freeze_cap, mint_cap) = coin::initialize<Duno>(
			account,
			name,
			symbol,
			8,
			true 
		);

		let duno_capabilities = DunoCapabilities {
			mint_cap: mint_cap,
			burn_cap: burn_cap,
			freeze_cap: freeze_cap
		};

		move_to(account, duno);
		move_to(account, duno_capabilities);
	}

	// Registers the account
	public entry fun register(account: &signer) {
		coin::register<Duno>(account);
	}

	// Returns the balance of the account
	public fun balance_of(account: address): u64 {
		coin::balance<Duno>(account)
	}

	// Mints the coins
	public entry fun mint(account: &signer, amount: u64) acquires Duno, DunoCapabilities {
		// Only the admin can mint the coins
		check_admin(account);

		// Check if the total supply is less than the max supply
		let duno = borrow_global_mut<Duno>(@Std);
		let total_supply = duno.total_supply;
		let max_supply = duno.max_supply;
		let new_total_supply = total_supply + amount;
		assert!(new_total_supply <= max_supply, 101);
		duno.total_supply = new_total_supply;

		// Mint the coins
		let duno_capabilities = borrow_global<DunoCapabilities>(signer::address_of(account));
		let mint_cap = &duno_capabilities.mint_cap;
		let coin = aptos_framework::coin::mint<Duno>(amount, mint_cap);
		coin::deposit<Duno>(signer::address_of(account), coin);
	}

	// Burns the coins
	public entry fun burn(account: &signer, amount: u64) acquires DunoCapabilities {
		// Check if the account has enough balance
		let balance = balance_of(signer::address_of(account));
		assert!(balance >= amount, 102);

		// Withdraw the coins
		let coin = coin::withdraw<Duno>(account, amount);
		
		// Burn the coins
		let duno_capabilities = borrow_global<DunoCapabilities>(signer::address_of(account));
		let burn_cap = &duno_capabilities.burn_cap;
		aptos_framework::coin::burn<Duno>(coin, burn_cap);
	}
}