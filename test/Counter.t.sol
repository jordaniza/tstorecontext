// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

contract ImplementsContext {
    struct Proposal {
        uint256 startBlock;
    }

    Proposal[] public proposals;

    function msgSender() public view returns (address) {
        bytes32 data = _readContext(this.msgSender.selector);
        address decoded = address(uint160(uint256(data)));
        return decoded == address(0) ? msg.sender : decoded;
    }

    function blockNumber() public view returns (uint256) {
        bytes32 data = _readContext(this.blockNumber.selector);
        uint256 decoded = uint(data);
        return decoded == 0 ? block.number : decoded;
    }

    function _readContext(
        bytes4 selector
    ) internal view returns (bytes32 data) {
        bytes32 slot = keccak256(abi.encodePacked(selector, address(this)));
        assembly {
            data := tload(slot)
        }
    }

    function setContext(bytes4 _selector, bytes32 _data) public {
        // write the value to a very specific storage slot determined by the address, the calldata and the selector
        bytes32 slot = keccak256(abi.encodePacked(_selector, address(this)));
        assembly {
            tstore(slot, _data)
        }
    }

    function createProposal() public {
        Proposal memory proposal = Proposal({startBlock: blockNumber()});

        proposals.push(proposal);
    }
}

contract ContextTest is Test {
    ImplementsContext context;

    function setUp() public {
        vm.roll(9999);
        context = new ImplementsContext();
    }

    function testItReturnsBlockNumberInTheBaseCase() public view {
        uint256 blockNumber = context.blockNumber();
        assertEq(blockNumber, block.number);
    }

    function testItReturnsTheContextBNInIfSet() public {
        uint256 bn = 10;
        context.setContext(context.blockNumber.selector, bytes32(bn));
        uint256 blockNumber = context.blockNumber();
        assertEq(blockNumber, 10);
    }

    function testCreateProposal() public {
        context.createProposal();
        uint256 blockNumber = context.proposals(0);
        assertEq(blockNumber, block.number);
    }

    function testCreateProposalWithSetContext() public {
        uint256 bn = 10;
        context.setContext(context.blockNumber.selector, bytes32(bn));
        context.createProposal();
        uint256 blockNumber = context.proposals(0);
        assertEq(blockNumber, 10);
    }
}
