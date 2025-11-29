// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title MyToken
 * @dev Custom ERC20 implementation without external dependencies
 */
contract MyToken {
    // Token metadata
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // Balances mapping
    mapping(address => uint256) public balanceOf;

    // Allowances mapping
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Constructor initializes the token with 1 million tokens (1,000,000 * 10^18)
     * All tokens are minted to the deployer address
     */
    constructor() {
        uint256 initialSupply = 1_000_000 * (10 ** uint256(decimals));
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    /**
     * @dev Transfer tokens from sender to recipient
     * @param _to The address of the recipient
     * @param _value The amount of tokens to transfer
     * @return success Whether the transfer was successful
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "transfer: recipient cannot be zero address");
        require(balanceOf[msg.sender] >= _value, "transfer: insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Approve spender to spend tokens on behalf of sender
     * @param _spender The address of the spender
     * @param _value The amount of tokens to approve
     * @return success Whether the approval was successful
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "approve: spender cannot be zero address");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another using allowance
     * @param _from The address of the token owner
     * @param _to The address of the recipient
     * @param _value The amount of tokens to transfer
     * @return success Whether the transfer was successful
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "transferFrom: sender cannot be zero address");
        require(_to != address(0), "transferFrom: recipient cannot be zero address");
        require(balanceOf[_from] >= _value, "transferFrom: insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "transferFrom: insufficient allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Get the allowance granted by owner to spender
     * @param _owner The address of the token owner
     * @param _spender The address of the spender
     * @return The remaining allowance
     */
    function getAllowance(address _owner, address _spender) public view returns (uint256) {
        return allowance[_owner][_spender];
    }
}
