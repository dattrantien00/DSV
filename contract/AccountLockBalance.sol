//SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.17;

contract AccountLockBalance {
    

    mapping (address => uint256) private lock_balances;
    uint8 rateUnlock= 10;
    function _lock_add(address _account, uint256 _amount) internal returns (bool) {
        lock_balances[_account] += _amount;
        return true;
    }

    function _lock_sub(address _account, uint256 _amount) internal returns (bool) {
        lock_balances[_account] -= _amount;
        return true;
    }

    function _lock_balanceOf(address _account) internal view returns (uint) {
        return lock_balances[_account];
    }

    function _unLockAmount(address _account) internal view returns (uint256){
        return lock_balances[_account]*rateUnlock/100;
    }
    
}