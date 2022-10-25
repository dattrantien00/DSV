//SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.17;

import "./ERC20.sol";

contract DSVToken is ERC20("DSV", "DSV",9*10**6*10**8, 9*10**6*10**8) { 
    address public feeaddr;
	uint256 public transferFeeRate;
	
    mapping(address => bool) private _transactionFee;
	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 */
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
		super._beforeTokenTransfer(from, to, amount);
		
	    if (from == address(0)) { // When minting tokens
			require(totalSupply().add(amount) <= maxSupply(), "ERC20Capped: max supply exceeded");
		}

	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
	    if (transferFeeRate > 0 && _transactionFee[recipient] == true && recipient != address(0) && feeaddr != address(0)) {
			uint256 _feeamount = amount.mul(transferFeeRate).div(100);
			super._transfer(sender, feeaddr, _feeamount); // TransferFee
			amount = amount.sub(_feeamount);
		}

		super._transfer(sender, recipient, amount);
	}

	/// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
	function mint(address _to, uint256 _amount) public onlyOwner {
		_mint(_to, _amount);
	}

	function burn(uint256 amount) public virtual returns (bool) {
		_burn(_msgSender(), amount);
		return true;
	}

	function burnFrom(address account, uint256 amount) public virtual returns (bool) {
		uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

		_approve(account, _msgSender(), decreasedAllowance);
		_burn(account, amount);
		return true;
	}
	
	function mintFrozenTokens(address account, uint256 amount) public onlyOwner returns (bool) {
        _mintfrozen(account, amount);
        return true;
    }
	
	function transferLockToken(address from, address to, uint256 amount) public onlyOwner returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _lock_sub(from, amount);
        _lock_add(to, amount);

        emit FrozenTransfer(from, to, amount);
        emit Transfer(from, to, amount);

        return true;
    }
    
    function unlockTokens(address account, uint256 amount) public onlyOwner returns (bool) {
        _melt(account, amount);
        return true;
    }
    
    function destroyLock(address account, uint256 amount) public onlyOwner {
        _burnFrozen(account, amount);
    }
    
    function addTransferFeeAddress(address _transferFeeAddress) public onlyOwner {
		_transactionFee[_transferFeeAddress] = true;
	}

	function removeTransferBurnAddress(address _transferFeeAddress) public onlyOwner {
		delete _transactionFee[_transferFeeAddress];
	}

    function setFeeAddr(address _feeaddr) public onlyOwner {
		feeaddr = _feeaddr;
    }
    
    function setTransferFeeRate(uint256 _rate) public onlyOwner {
        require(_rate <= 10,"Maximum rate is 10");
 		transferFeeRate = _rate;
    }
    
   

	constructor() public {
	    feeaddr = msg.sender;
		transferFeeRate = 0;
	}
    
}
