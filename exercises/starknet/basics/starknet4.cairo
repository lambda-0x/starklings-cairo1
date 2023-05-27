// starknet4.cairo
// Liz, a friend of Jill, wants to manage inventory for her store on-chain.
// This is a bit challenging for Joe and Jill, Liz prepared an outline
// for how contract should work, can you help Jill and Joe write it?
// Execute `starklings hint starknet4` or use the `hint` watch subcommand for a hint.

#[contract]
mod LizInventory {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use array::ArrayTrait;

    struct Storage {
        contract_owner: ContractAddress,
        // TODO: add storage inventory, that maps product (felt252) to stock quantity (u32)
        inventory: LegacyMap<felt252, u32>,
    }

    #[constructor]
    fn constructor(owner: ContractAddress) {
        contract_owner::write( owner );
    }

    #[external]
    fn add_stock(product: felt252, new_stock: u32) {
        assert(get_caller_address() == contract_owner::read(), 'Only owner can call');
        let old_stock = inventory::read(product);
        inventory::write(product, old_stock + new_stock);
    }

    #[external]
    fn purchase(product: felt252, quantity: u32) {
        let old_stock = inventory::read(product);
        if quantity > old_stock {
            let mut data = ArrayTrait::new();
            data.append('stock less then order');
            panic(data)
        }

        inventory::write(product, old_stock - quantity);
    }

    #[view]
    fn get_stock(product: felt252) -> u32 {
        inventory::read(product)
    }
}

#[cfg(test)]
mod test {
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use array::SpanTrait;
    use debug::PrintTrait;
    use traits::TryInto;

    use starknet::Felt252TryIntoContractAddress;
    use option::OptionTrait;
    use super::LizInventory;

    #[test]
    #[available_gas(2000000000)]
    fn test_owner() {

        let owner: felt252 = 'Elizabeth';
        let owner: ContractAddress = owner.try_into().unwrap();
        LizInventory::constructor(owner);

        // Check that contract owner is set
        let contract_owner = LizInventory::contract_owner::read();
        assert(contract_owner == owner, 'Elizabeth should be the owner');
    }

    #[test]
    #[available_gas(2000000000)]
    fn test_stock() {
        let owner = util_felt_addr( 'Elizabeth' );
        LizInventory::constructor(owner);

        // Call contract as owner
        starknet::testing::set_caller_address( owner );

        // Add stock
        LizInventory::add_stock( 'Nano', 10_u32 );
        let stock = LizInventory::get_stock( 'Nano' );
        assert( stock == 10_u32, 'stock should be 10' );

        LizInventory::add_stock( 'Nano', 15_u32 );
        let stock = LizInventory::get_stock( 'Nano' );
        assert( stock == 25_u32, 'stock should be 25' );
    }

    #[test]
    #[available_gas(2000000000)]
    fn test_stock_purchase() {
        let owner = util_felt_addr( 'Elizabeth' );
        LizInventory::constructor(owner);

        // Call contract as owner
        starknet::testing::set_caller_address( owner );

        // Add stock
        LizInventory::add_stock( 'Nano', 10_u32 );
        let stock = LizInventory::get_stock( 'Nano' );
        assert( stock == 10_u32, 'stock should be 10' );

        // Call contract as owner
        starknet::testing::set_caller_address( 0.try_into().unwrap() );

        LizInventory::purchase( 'Nano', 2 );
        let stock = LizInventory::get_stock( 'Nano' );
        assert( stock == 8_u32, 'stock should be 8' );
    }

    #[test]
    #[should_panic]
    #[available_gas(2000000000)]
    fn test_set_stock_fail() {
        let owner = util_felt_addr( 'Elizabeth' );
        LizInventory::constructor(owner);
        // Try to add stock, should panic to pass test!
        LizInventory::add_stock( 'Nano', 20_u32 );
    }

    #[test]
    #[should_panic]
    #[available_gas(2000000000)]
    fn test_purchase_out_of_stock() {
        let owner = util_felt_addr( 'Elizabeth' );
        LizInventory::constructor(owner);
        // Purchse out of stock
        LizInventory::purchase( 'Nano', 2_u32 );
    }

    fn util_felt_addr(addr_felt: felt252) -> ContractAddress {
        addr_felt.try_into().unwrap()
    }
}
