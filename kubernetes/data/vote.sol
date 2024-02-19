// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Voting
 * @dev Perform votes with an arbitrary number of voters and arbitrary choices, with delegation
 */
contract Voting {
    address public owner; // The owner of the contract, allowed to create votes

    struct Ballot {
        address voter; // Address of the voter
        // Address of the proxy voter to which we transferred our vote
        address proxy; // THE VOTE IS A DELEGATION IF THIS IS NOT EQUAL TO address(0)
        uint8 choice; // Index of the choosen vote option, proxy takes precedence over it if different than address(0)
    }

    struct Verdict {
        string name; // Name of the current vote
        string[] options; // Voting options
        uint256[] votes; // Voices for each results
    }

    // Current vote data
    Ballot[] public ballots; // Ballots emited for the current vote
    mapping(address => uint256) private address2ballot; // Address to ballot index mapping
    // Previous and current verdicts
    Verdict[] private verdicts; // Previous and current votes results

    /**
     * @dev Initialize a new vote
     * @param voteName of the new vote
     * @param opt1 name of the first voting option
     * @param opt2 name of the second voting option
     */
    function initVote(
        string memory voteName,
        string memory opt1,
        string memory opt2
    ) private {
        // Initialize a new vote in the array;
        Verdict storage tmp = verdicts.push();
        tmp.name = voteName;
        tmp.options.push(opt1);
        tmp.options.push(opt2);
        verdicts[verdicts.length - 1].votes.push(0);
        verdicts[verdicts.length - 1].votes.push(0);
    }

    /**
     * @dev Instantiate this contract with two initial options and define the owner
     */
    constructor(
        string memory voteName,
        string memory opt1,
        string memory opt2
    ) {
        owner = msg.sender; // The owner is the one sending the creation message
        initVote(voteName, opt1, opt2); // Initialize contract with an initial vote
    }

    /**
     * @dev Create a new vote (same as init but only the owner can)
     * @param voteName of the new vote
     * @param opt1 name of the first voting option
     * @param opt2 name of the second voting option
     */
    function newVote(
        string memory voteName,
        string memory opt1,
        string memory opt2
    ) public {
        require(
            msg.sender == owner,
            "Seul le proprietaire peut creer un nouveau vote"
        );
        delete ballots;
        initVote(voteName, opt1, opt2);
    }

    /**
     * @dev Add a new vote option
     * @param option to add
     */
    function addOption(string memory option) public {
        require(
            msg.sender == owner,
            "Seul le proprietaire peut ajouter un choix de vote"
        );

        verdicts[verdicts.length - 1].options.push(option);
        verdicts[verdicts.length - 1].votes.push(0);
    }

    /**
     * @dev Issue a vote by choosing an option
     * @param optionIndex of the option choosen
     */
    function vote(uint8 optionIndex) public {
        require(
            optionIndex < verdicts[verdicts.length - 1].options.length,
            "Veuillez selectionner une des options disponible"
        );

        uint256 ballotIndex = address2ballot[msg.sender]; // Get the sender's ballot index

        if (ballots.length > 0 && ballots[ballotIndex].voter == msg.sender) {
            // If vote already exists, modify it
            ballots[ballotIndex].proxy = address(0);
            ballots[ballotIndex].choice = optionIndex;
        } else {
            // Deposit a new ballot
            ballots.push(
                Ballot({
                    voter: msg.sender,
                    proxy: address(0),
                    choice: optionIndex
                })
            );
            // Add it to the hashmap
            address2ballot[msg.sender] = ballots.length - 1;
        }
    }

    /**
     * @dev Proxy your vote to the proxy address
     * @param voteProxy address to which vote is delegated
     */
    function delegate(address voteProxy) public {
        require(
            voteProxy != msg.sender,
            "Vous ne pouvez pas deleguer un vote a vous meme"
        );

        uint256 ballotIndex = address2ballot[msg.sender]; // Get the sender's ballot index
        uint256 proxyBallotIndex = address2ballot[voteProxy]; // Get the sender's proxy ballot index

        // Get the proxy defined by the proxy if the proxy already voted
        if (ballots.length > proxyBallotIndex) {
            // Prevent delegation loops if the proxy has a proxy
            if (ballots[proxyBallotIndex].proxy != address(0)) {
                address proxyProxy = ballots[proxyBallotIndex].proxy;
                // If the delegate has also delegated
                require(
                    proxyProxy != msg.sender,
                    "Vous ne pouvez pas deleguer votre vote a quelqu'un vous ayant deja delegue le sien"
                );
                // Handle delegation loops
                Ballot memory proxyBallot = ballots[address2ballot[proxyProxy]];
                while (proxyBallot.proxy != address(0)) {
                    require(
                        proxyBallot.proxy != msg.sender,
                        "Vous ne pouvez pas deleguer votre vote a quelqu'un vous ayant deja indirectement delegue le sien"
                    );
                    proxyBallot = ballots[address2ballot[proxyBallot.proxy]];
                }
            }
        }

        if (ballots[ballotIndex].voter == msg.sender) {
            // If vote already exists, modify it
            ballots[ballotIndex].proxy = voteProxy;
            ballots[ballotIndex].choice = 0;
        } else {
            // Deposit a new ballot
            ballots.push(
                Ballot({voter: msg.sender, proxy: voteProxy, choice: 0})
            );
            // Add it to the hashmap
            address2ballot[msg.sender] = ballots.length - 1;
        }
    }

    /**
     * @dev Display the options for the previous verdict in the past (0 is current)
     * @param previous how many verdicts in the past
     * @return _options the options
     */
    function options(uint256 previous)
        public
        view
        returns (string[] memory _options)
    {
        return verdicts[verdicts.length - 1 - previous].options;
    }

    mapping(address => uint256) private delegations; // Store accumulated delegations

    /**
     * @dev Display the votes for the previous verdict in the past (0 is current)
     * @param previous how many verdicts in the past
     * @return _votes the votes
     */
    function votes(uint256 previous) public returns (uint256[] memory _votes) {
        require(
            ballots.length > 0,
            "Le vote ne comporte pas encore assez de votes pour etre compte"
        );

        // If displaying old vote, return directly
        if (previous > 0) {
            return verdicts[verdicts.length - 1 - previous].votes;
        }

        // Reset delegations
        for (uint256 i = 0; i < ballots.length; i++) {
            if (ballots[i].proxy != address(0)) {
                delegations[ballots[i].proxy] = 0;
            }
        }

        // Reset votes
        for (
            uint256 i = 0;
            i < verdicts[verdicts.length - 1].votes.length;
            i++
        ) {
            verdicts[verdicts.length - 1].votes[i] = 0;
        }

        // Count delegations
        for (uint256 i = 0; i < ballots.length; i++) {
            if (ballots[i].proxy != address(0)) {
                delegations[ballots[i].proxy] +=
                    1 +
                    delegations[ballots[i].voter];
                delegations[ballots[i].voter] = 0;
            }
        }

        // Count votes then
        for (uint256 i = 0; i < ballots.length; i++) {
            if (ballots[i].proxy == address(0)) {
                verdicts[verdicts.length - 1].votes[ballots[i].choice] +=
                    1 +
                    delegations[ballots[i].voter];
            }
        }
        return verdicts[verdicts.length - 1].votes;
    }
}
