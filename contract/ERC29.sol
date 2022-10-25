//SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./AccountLockBalance.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract ERC20 is Ownable, AccountLockBalance, IERC20{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private _totalSupply;
	uint256 private _maxSupply;
	
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	constructor (string memory name, string memory symbol, uint256 max, uint total) public {
		_name = name;
		_symbol = symbol;
		_decimals = 18;
		_maxSupply = max;
		_totalSupply = total;
		_balances[address(msg.sender)] = total;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}
	
	function maxSupply() public view returns (uint256) {
		return _maxSupply;
	}

	function availableBalance(address account) public view returns (uint256) {
		return _balances[account];
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account].add(_lock_balanceOf(account));
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _setupDecimals(uint8 decimals_) internal {
		_decimals = decimals_;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
		require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
	}

    // mint locked token to user
	function _mintlock(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint frozen to the zero address");
        require(account != address(this), "ERC20: mint frozen to the contract address");
        require(amount > 0, "ERC20: mint frozen amount should be > 0");
        require(_totalSupply.add(amount) <= _maxSupply, "ERC20Capped: max supply exceeded");

        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(this), account, amount);

        _lock_add(account, amount);

        emit MintLock(account, amount);
    }
	
    // lock more token
	function _lock(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: freeze from the zero address");
        require(amount > 0, "ERC20: freeze from the address: amount should be > 0");

        _balances[account] = _balances[account].sub(amount);
        _lock_add(account, amount);

        emit Lock(account, amount);
    } 

    // burn locked token
    function _burnLock(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: frozen burn from the zero address");

        _totalSupply = _totalSupply.sub(amount);
        _lock_sub(account, amount);

        emit Transfer(account, address(this), amount);
    }
	
    // unlock token
    function _unlock(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: melt from the zero address");
        require(amount > 0, "ERC20: melt from the address: value should be > 0");
        require(_lock_balanceOf(account) >= amount, "ERC20: melt from the address: balance < amount");

        _lock_sub(account, amount);
        emit Unlock(account, amount);
        
        _balances[account] = _balances[account].add(amount);
        // emit Transfer(address(this), account, amount);
    }

    event Unlock(address account,uint256 amount);
    event Lock(address indexed from, uint256 amount);
    event MintLock(address indexed to, uint256 amount);
    event LockTransfer(address indexed from, address indexed to, uint256 value);


    // reward for attendance
    uint256 constant timelock= 1 days;
    IERC20 private token;
    uint256 constant reward = 10*10**18;
    mapping(address => uint256) status;

    event takeReward(address _add);
    
    // user only get attendance after 1 day
    function attendanceReward() public{
        require(checkstatus(msg.sender),"cannot attendance");
        
        token.transfer(msg.sender, reward);
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

    //unlock 10% token after every 3 months
	uint256 unlocktime=block.timestamp+ 90 days;
	function unlockafter3months(address _account)
	{
		require(block.timestamp > unlocktime, "not time to unlock");
		uint256 amount = _unLockAmount(_account);
		_unlock(_account, amount);
	}
	
}