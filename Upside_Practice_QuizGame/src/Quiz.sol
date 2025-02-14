// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    address public owner;

    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }

    Quiz_item[] public quizList;
    
    mapping(address => uint)[] public bets; //배열형 매핑 -> bets[quizId][address]=amount
    mapping(address => uint) public claim_money;
    uint public vault_balance;


    constructor () {
        owner=msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"Not Owner");
        _;
    }

    function addQuiz(Quiz_item memory q) public onlyOwner {
        q.id=quizList.length+1;
        quizList.push(q);
        bets.push();
    }

    function getAnswer(uint quizId) public view returns (string memory){
        return quizList[quizId-1].answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        require(quizId > 0 && quizId <= quizList.length, "Invalid quizId");
        Quiz_item memory q = quizList[quizId - 1];
        q.answer = "";
        return q;
    }

    function getQuizNum() public view returns (uint){
        return quizList.length;
    }
    
    function betToPlay(uint quizId) public payable {
        require(quizId > 0 && quizId <= quizList.length, "Invalid quizId");
        require(msg.value >= quizList[quizId - 1].min_bet && msg.value <= quizList[quizId - 1].max_bet, "Bet is wrong");
        require(bets[quizId-1][msg.sender]<=quizList[quizId - 1].max_bet,"Bet is wrong");
        bets[quizId-1][msg.sender] += msg.value; 
     
        vault_balance += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        require(quizId > 0 && quizId <= quizList.length, "Invalid quizId");
        require(bets[quizId-1][msg.sender]>0,"No Betting!!");
        uint betAmount = bets[quizId-1][msg.sender];
        uint reward = betAmount * 2;

        
        if (keccak256(abi.encodePacked(ans)) == keccak256(abi.encodePacked(getAnswer(quizId)))) {
            vault_balance -= reward; 
            bets[quizId-1][msg.sender] = 0;
            claim_money[msg.sender]+=reward;
            return true;
        }
        bets[quizId-1][msg.sender]=0;
        vault_balance+=betAmount;
        return false;
    
    }

    function claim() public {
        uint reward = claim_money[msg.sender];
        require(reward>0,"No reward");
        require(vault_balance >= reward, "Not enough funds in contract"); 
        payable(msg.sender).transfer(reward);
        claim_money[msg.sender]=0;
    }

    receive() external payable{
        vault_balance += msg.value; 
    }
    

}
