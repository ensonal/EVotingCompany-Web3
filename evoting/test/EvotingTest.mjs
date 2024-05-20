import hardhat from "hardhat";
import { describe, it, beforeEach } from "mocha";
import chai from "chai";
import { solidity } from "ethereum-waffle";

chai.use(solidity);
const { expect } = chai;

let ethers;

(async () => {
  const { ethers: _ethers } = hardhat;
  ethers = _ethers;

  runTests();
})();

function runTests() {
  describe("Evoting Contract", function () {
    let Evoting;
    let evoting;
    let owner;
    let addr1;
    let addr2;
    let addr3;
    let addrs;

    const proposalNames = [
      ethers.utils.formatBytes32String("Proposal1"),
      ethers.utils.formatBytes32String("Proposal2"),
    ];

    beforeEach(async function () {
      Evoting = await ethers.getContractFactory("Evoting");
      [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
      evoting = await Evoting.deploy(proposalNames);
      await evoting.deployed();
    });

    it("Should set the right chairperson", async function () {
      expect(await evoting.chairperson()).to.equal(owner.address);
    });

    it("Should allow the chairperson to give right to vote", async function () {
      await evoting.giveRightToVote(addr1.address);
      const voter = await evoting.voters(addr1.address);
      expect(voter.weight).to.equal(1);
    });

    it("Should not allow non-chairperson to give right to vote", async function () {
      await expect(evoting.connect(addr1).giveRightToVote(addr2.address)).to.be.revertedWith(
        "Only the Chairperson can give access to vote"
      );
    });

    it("Should allow a voter to vote", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.connect(addr1).vote(0);
      const voter = await evoting.voters(addr1.address);
      expect(voter.voted).to.be.true;
      expect(voter.voteCounted).to.be.true;

      const proposal = await evoting.proposals(0);
      expect(proposal.voteCount).to.equal(1);
    });

    it("Should not allow a voter to vote twice", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.connect(addr1).vote(0);
      await expect(evoting.connect(addr1).vote(0)).to.be.revertedWith("Already voted");
    });

    it("Should correctly delegate a vote", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.giveRightToVote(addr2.address);
      await evoting.connect(addr1).delegate(addr2.address);

      const voter1 = await evoting.voters(addr1.address);
      const voter2 = await evoting.voters(addr2.address);
      expect(voter1.weight).to.equal(0);
      expect(voter2.weight).to.equal(2);
    });

    it("Should return the correct winning proposal", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.giveRightToVote(addr2.address);
      await evoting.connect(addr1).vote(0);
      await evoting.connect(addr2).vote(1);

      let winningProposal = await evoting.winningProposal();
      expect(winningProposal).to.equal(0);

      await evoting.giveRightToVote(addr3.address);
      await evoting.connect(addr3).vote(1);

      winningProposal = await evoting.winningProposal();
      expect(winningProposal).to.equal(1);
    });

    it("Should return the correct winning name", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.giveRightToVote(addr2.address);
      await evoting.connect(addr1).vote(0);
      await evoting.connect(addr2).vote(1);

      let winningName = await evoting.winningName();
      expect(ethers.utils.parseBytes32String(winningName)).to.equal("Proposal1");

      await evoting.giveRightToVote(addr3.address);
      await evoting.connect(addr3).vote(1);

      winningName = await evoting.winningName();
      expect(ethers.utils.parseBytes32String(winningName)).to.equal("Proposal2");
    });

    it("Should check if a voter's vote has been counted", async function () {
      await evoting.giveRightToVote(addr1.address);
      await evoting.connect(addr1).vote(0);
      let voteCounted = await evoting.isVoteCounted(addr1.address);
      expect(voteCounted).to.be.true;

      voteCounted = await evoting.isVoteCounted(addr2.address);
      expect(voteCounted).to.be.false;
    });
  });
}
