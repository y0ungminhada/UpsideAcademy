// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "forge-std/console.sol";

contract Lottery {
    enum LotteryPhase { Sell, Draw, Claim }

    struct Lottery_item {
        address owner;
        uint256 sellPhaseEndTime;
        uint16 number;
    }

    Lottery_item[] public lotteryList;
    LotteryPhase public currentPhase;

    mapping(uint256 => mapping(address => uint)) public bets;// 로또 번호 -> 산 사람 -> 배팅금액
    mapping(uint16 => uint256) public buyCount; // 각 번호별 구매 횟수 저장
    uint256 public payout; // 당첨자에게 줄 당첨금 계산
    uint16[] public boughtNumbers; // 구매된 로또 번호 리스트
    uint16 public LotteryNum;
    uint public received_msg_value; //테스트 컨트랙트로부터 받는 돈 저장(사용자들의 bet금액도)
    uint256 public claimedWinners;// 당첨금을 찾은 사람 수
    uint16 constant UNDEFINED_LOTTERY = 1000;// 로또 번호가 정해지지 않았음을 의미
    
    constructor() {
        startNewRound();
    }

    function getPhase() public view returns (LotteryPhase) {
        return currentPhase;
    }

    modifier onlyDuringSellPhase() {
        require(block.timestamp < lotteryList[0].sellPhaseEndTime, "Sell phase is over");
        _;
    }


    // 처음 로또가 만들어지고 24시간 동안만 해당 번호의 로또 구매 가능
    // 24시간 이후부터 draw할 수 있고, draw전까지는 로또번호가 정해지지 않음
    // 24시간 이후에 draw할 수 있고, draw후에 로또번호가 정해짐
    function updatePhase() public {
        uint lastIndex = lotteryList.length - 1;
        if (block.timestamp >= lotteryList[lastIndex].sellPhaseEndTime && currentPhase == LotteryPhase.Sell) {
            currentPhase = LotteryPhase.Draw;
        } else if (currentPhase == LotteryPhase.Draw) {
            currentPhase = LotteryPhase.Claim;
        }
    }

    // 새로운 라운드 시작
    function startNewRound() internal {
        delete lotteryList;
        // 기존 매핑 초기화 (구매된 모든 번호를 순회하여 0으로 설정)
        for (uint i = 0; i < boughtNumbers.length; i++) {
            delete buyCount[boughtNumbers[i]];
        }
        delete boughtNumbers; // 배열 초기화
        Lottery_item memory l;
        l.owner = msg.sender;
        l.sellPhaseEndTime = block.timestamp + 24 hours;
        l.number = UNDEFINED_LOTTERY;
        lotteryList.push(l);
        received_msg_value = received_msg_value;
        payout = 0;
        claimedWinners = 0;
        currentPhase = LotteryPhase.Sell;
    }

    function buy(uint16 BuyNum) public payable onlyDuringSellPhase {
        require(msg.value == 0.1 ether, "wrong");
        require(bets[BuyNum][msg.sender] == 0, "Double Buy");

        buyCount[BuyNum]++; // 해당 로또 번호의 구매 횟수 증가
        bets[BuyNum][msg.sender] = msg.value;
        received_msg_value += msg.value;
    }

    // 당첨번호 출력
    function draw() public returns (uint16) {
        updatePhase();
        require(currentPhase == LotteryPhase.Draw, "Not Yet");
        uint16 randSeed = 0;
        // LotteryNum은 0~999 범위로 제한
        LotteryNum = uint16(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, randSeed))) % 1000);

        uint256 totalWinner = getWinnerCount(LotteryNum);
        if (totalWinner > 0) {
            payout = received_msg_value / totalWinner;
        }

        return LotteryNum;
    }

    function winningNumber() public view returns (uint16) {
        return LotteryNum;
    }

    function getWinnerCount(uint16 _lotteryNum) internal view returns (uint256) {
        return buyCount[_lotteryNum];
    }

    function isWinner(address owner) public view returns (bool) {
        return bets[LotteryNum][owner] > 0;
    }

    function claim() public {
        updatePhase();
        require(currentPhase == LotteryPhase.Claim, "Not Yet");

        uint256 totalWinners = getWinnerCount(LotteryNum);

        if (payout == 0) {
            startNewRound();// 당첨자가 없으면 새로운 라운드 시작
            return;
        }

        require(isWinner(msg.sender), "You are not winner");

        received_msg_value -= payout;
        bets[LotteryNum][msg.sender] = 0;
        claimedWinners++;
        (bool success, ) = msg.sender.call{value: payout}("");
        require(success, "Transfer failed");


        // 모든 당첨자가 당첨금을 찾아갔을 경우 새로운 라운드 시작
        if (claimedWinners >= totalWinners) {
            startNewRound();
        }
    }

}