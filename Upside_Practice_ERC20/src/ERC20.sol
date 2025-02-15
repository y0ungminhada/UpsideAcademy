// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "forge-std/console.sol";

contract ERC20 {
    

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    bool public paused = false; // 컨트랙트 전체 정지 여부
    bytes32 public immutable DOMAIN_SEPARATOR;


    mapping(address  => uint256) private balances;
    mapping (address => mapping(address => uint256)) private allowances;
    mapping(address  => uint256) private nonce;

    event Transfer(address from, address to, uint256 value);
    event Paused();
    event Unpaused();
    event Approval(address owner, address spender, uint256 value);


    constructor(string memory _name, string memory _symbol)  {
        name=_name;
        symbol = _symbol;
        owner=msg.sender;
        totalSupply = 1000000 * 10**decimals; // 초기 공급량
        balances[msg.sender] = totalSupply;
        
        uint256 chainId;
        assembly {
            chainId := chainid() // 현재 체인 ID 가져오기
        }

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)), // 토큰 이름
            keccak256(bytes("1")), // 버전
            chainId,
            address(this)
        ));

    }


    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner");
        _;
    }
    //퍼즈 모디파이어 추가해보기


    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public onlyOwner  returns(bool){
        require(balanceOf(msg.sender)>0,"caller must have a balance of at least amount");
        require(to != address(0),"cannot be the zero address");
        require(!paused,"Contract is paused");
        balances[msg.sender]-=amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function pause() public onlyOwner  {
        paused = true;
        emit Paused();
    }
    
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }
    

    function approve(address spender, uint256 amount) public returns (bool){
        require(spender!=address(0) && msg.sender!=address(0),"ERC20: cannot be the zero address");
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address from, address to) public view returns (uint256) {
        return allowances[from][to]; 
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool){
        require(allowances[from][msg.sender]>=amount,"ERC20: transfer amount exceeds allowance");
        require(balances[from]>=amount,"ERC20: insufficient balance");
        require(to != address(0),"ERC20: cannot be the zero address");

        balances[from]-=amount;
        balances[to]+=amount;
        allowances[from][msg.sender]-=amount;

        emit Transfer(from, to, amount);
        return true;
    }   

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32){
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    } 

    //맨처음에는 nonce[addr]++를 했었는데 이렇게 하면 테스트코드에서 nonce를 불러와서 nonce가 2가 됨
    //그래서 nonces를 그냥 return하는 함수로 구현
    function nonces(address addr) public view returns (uint256){
        return nonce[addr];
    }

    
    function permit(
        address from,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public  {
        require(block.timestamp<=deadline,"PERMIT_DEADLINE_EXPIRED");
        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            from, 
            to, 
            value, 
            nonces(from), 
            deadline
            ));
        bytes32 digest = _toTypedDataHash(hash);
        address recoverAddress = ecrecover(digest, v, r, s);
        require(recoverAddress != address(0) && recoverAddress == from, "INVALID_SIGNER");
        nonce[from]++;
        allowances[from][to]=value;
        emit Approval(from, to, value);
    }
}



