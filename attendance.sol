//SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
contract attendance is Ownable{
    uint256 constant timelock= 1 days;
    IERC20 private token;
    uint256 constant reward = 10;
    mapping(address => uint256) status;

    event takeReward(address _add);
    constructor(IERC20 _token)
    {
        token=_token;
        
    }


    function attendanceReward() public{
        require(checkstatus(msg.sender),"cannot attendance");
        
        token.transfer(msg.sender, 10*10**18);
        updatestatus(msg.sender);
        
        emit takeReward(msg.sender);
        
    }

    function updatestatus(address _address) internal {
        status[_address]= block.timestamp + timelock;
    }
    function checkstatus(address _address) internal view returns(bool)
    {
        if(status[_address] == 0 )
        {
            return true;
        }
        else
        {
            if(block.timestamp >= status[_address]){
                return true;
            }
            
            {
                return false;
            }
        }
    }
}