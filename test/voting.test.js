const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
    it("devrait permettre à l'administrateur de commencer l'enregistrement des votants", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();

        await voting.startProposalsRegistration();
        const status = await voting.status();
        expect(status).to.equal(1, "Le statut devrait être ProposalsRegistrationStarted");
    });

    it("ne devrait pas permettre à un non-administrateur de commencer l'enregistrement des votants", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();

        const nonOwnerAccount = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"; // Remplacez par une adresse Ethereum non propriétaire
        try {
            await voting.startProposalsRegistration({ from: nonOwnerAccount });
            expect.fail("Le non-administrateur a pu commencer l'enregistrement des votants (ce qui n'était pas attendu).");
        } catch (error) {
            expect(error.message).to.include("Only the owner can start proposals registration");
        }
    });

    it("devrait permettre à l'administrateur de commencer l'enregistrement des votes", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();

        const ownerAddress = await voting.owner();
        await voting.startProposalsRegistration({ from: ownerAddress });
        const status = await voting.status();
        expect(status).to.equal(1, "Le statut devrait être ProposalsRegistrationStarted");
    });

    it("devrait permettre au propriétaire de transférer la propriété du contrat", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();
        
        const ownerAccount = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"; // Remplacez par une adresse Ethereum comme nouveau propriétaire
        await voting.transferOwnership(ownerAccount);
        const owner = await voting.owner();
        expect(owner).to.equal(ownerAccount, "La propriété n'a pas été transférée avec succès.");
    });

    it("devrait permettre à un votant enregistré de voter", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();

        const ownerAddress = await voting.owner();
        await voting.startProposalsRegistration({ from: ownerAddress });
        await voting.endProposalsRegistration({ from: ownerAddress });
        await voting.startVotingSession({ from: ownerAddress });

        const voterAddress = "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"; // Remplacez par l'adresse du votant
        await voting.registerVoter(voterAddress);

        const proposalDescription = "Nouvelle proposition"; // Remplacez par la description de la proposition
        await voting.submitProposal(proposalDescription);
        const proposalId = 0;
        await voting.vote(proposalId, { from: voterAddress });
        const voter = await voting.voters(voterAddress);
        expect(voter.hasVoted).to.equal(true, "Le votant n'a pas pu voter.");
        expect(voter.votedProposalId).to.equal(proposalId, "Le votant n'a pas voté pour la bonne proposition.");
    });


    it("devrait permettre au propriétaire de clôturer la session de vote et de dépouiller les votes", async () => {
        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();
        await voting.deployed();

        const ownerAddress = await voting.owner();
        await voting.startProposalsRegistration({ from: ownerAddress });
        await voting.endProposalsRegistration({ from: ownerAddress });
        await voting.startVotingSession({ from: ownerAddress });
        await voting.endVotingSession({ from: ownerAddress });
        await voting.tallyVotes({ from: ownerAddress });
        const status = await voting.status();
        expect(status).to.equal(5, "Le statut devrait être 'VotesTallied'");
        const winningProposalId = await voting.winningProposalId();
        expect(winningProposalId).to.equal(0, "La proposition gagnante devrait avoir l'ID 0.");
    });
});