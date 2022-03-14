// scoped to between buddies for petty cash. There will be a lack of remediation tooling.

// 1 smart contract

contract GoGoBet {
    address[] betters;
    // address[] hasPaid;
    mapping(address => bool) private hasPaid;
    address oracle;
    uint256 amount;
    uint256 betAmount;
    bool hasPendingBet;

    constructor() {
        // setSettingUint("members.quorum", 0.50 ether); // Member quorum threshold that must be met for proposals to pass (51%)
    }

    // The member proposal quorum threshold for this DAO
    // function getQuorum() external view override returns (uint256) {
    //     return getSettingUint("members.quorum");
    // }

    // function setUint(bytes32 _key, uint256 _value) internal {
    //     GoGoBet.setUint(_key, _value);
    // }

    function isOracleInBetters(
        address[] memory _proposedBetters,
        address _proposedOracle
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _proposedBetters.length; i++) {
            if (_proposedBetters[i] == _proposedOracle) return true;
        }
        return false;
    }

    function createNewBet(
        address[] memory proposedBetters,
        address proposedOracle,
        uint256 proposedBetAmount
    ) public payable {
        // check if a bet is currently active. If yes, respond with error
        require(
            !hasPendingBet,
            "Bet is currently in progress, can't begin new bet"
        );
        require(
            proposedBetAmount > 0,
            "Proposed bet amount must be greater than 0. "
        );
        // check that better added the proposed amount to the transaction
        require(
            msg.value == proposedBetAmount,
            "Bet creator must stake bet amount"
        );

        require(
            !isOracleInBetters(proposedBetters, proposedOracle),
            "Proposed Oracle can not also be one of the betters. "
        );

        // check that proposed oracle address is a valid web3 address
        // require(
        //     isAddress(proposedOracle),
        //     "Proposed Oracle address must be a valid address"
        // );

        // save betters
        betters = proposedBetters;
        // save proposedOracle
        oracle = proposedOracle;
        // add better to hasPaid array
        // hasPaid.push(msg.sender);
        hasPaid[msg.sender] = true;
        // set hasPendingBet to true
        hasPendingBet = true;
        // set betAmount to proposedBetAmount
        betAmount = proposedBetAmount;
    }

    function isSenderInBetters(address _sender) internal view returns (bool) {
        for (uint256 i = 0; i < betters.length; i++) {
            if (betters[i] == _sender) return true;
        }
        return false;
    }

    function isSenderInHasPaid(address _sender) internal view returns (bool) {
        if (hasPaid[_sender]) {
            return true;
        } else return false;
    }

    // validates that the msg.sender is a better and hasn't already paid, and accepts their funds. else, reverts the transaction
    function addBetter() public payable {
        require(
            !isSenderInBetters(msg.sender),
            "Message sender must be in the proposed betters array"
        );

        require(
            !isSenderInHasPaid(msg.sender),
            "Better has already paid to join the bet. "
        );

        require(
            msg.value == betAmount,
            "Better must add the exact bet amount to join the bet. "
        );

        hasPaid[msg.sender] = true;
    }

    function checkAllBettersHavePaid() internal view returns (bool) {
        for (uint256 i = 0; i < betters.length; i++) {
            if (hasPaid[betters[i]] != true) return false;
        }
        return true;
    }

    function decideBet(address betWinner) public {
        require(
            hasPendingBet,
            "No bet is currently pending, cannot make decision on bet. "
        );
        // validate that msg.sender is the oracle
        require(msg.sender == oracle, "Only Oracle can decide a bet. ");
        // validate that all addresses in betters is in hasPaid
        require(
            checkAllBettersHavePaid(),
            "Cannot make decision on bet, not every better has paid. "
        );

        // create payable address for the winner
        address payable winner;
        winner = payable(betWinner);
        (bool success, ) = winner.call{value: address(this).balance}("");

        // if this fails what happens to the money? Stays in the smart contract? Gets reverted back to the contract?
        require(success, "Failed to send money");

        hasPendingBet = false;
        clearHasPaid();
        oracle = address(0);
        amount = 0;
        betAmount = 0;
        delete betters;
    }

    function clearHasPaid() internal {
        for (uint256 i = 0; i < betters.length; i++) {
            hasPaid[betters[i]] = false;
        }
    }

    // public function to return amount collected so far
    function getTotalAmount() public view returns (uint256) {
        return address(this).balance;
    }

    // public function to return amount the bet is for eg. I bet 5 dollars!
    function getAmount() public view returns (uint256) {
        return amount;
    }

    function getOracle() public view returns (address) {
        return oracle;
    }

    function getBetters() public view returns (address[] memory) {
        return betters;
    }

    // function getHasPaid() public view returns (address[] memory) {
    //     address[] memory ret = new address[](hasPaidCount);
    //     for (uint256 i = 0; i < hasPaidCount; i++) {
    //         ret[i] = addresses[i];
    //     }
    //     return ret;
    // }

    //
    // function proposeCancelBet() public {
    //     // check if hasActiveBet is true. If false, return
    //     // add msg.sender to cancelBet map
    //     // check if 50%< addresses in betters is in cancelBet map
    //     // check if
    // }

    // // if 100% quorum, cancel the bet and return money
    // function executeCancelBet() public {}
}
