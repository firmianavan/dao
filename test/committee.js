var Committee = artifacts.require("./Committee.sol");

contract('Committee', function(accounts) {
  console.log(accounts);
  it("ownner should be set right", function() {
    return Committee.new().then(function(instance) {
      // console.log(instance);
      return instance.ownner();
    }).then(function(ownner) {
      assert.equal(ownner.valueOf(), accounts[0], "invalid account ownner");
    });
  });
  it("Candidate cannot be voted before register", function() {
    return Committee.new().then(function(instance) {
      return instance.vote(accounts[0],{value:100000,from:accounts[1]});
    }).catch(e=>{
      assert.notEqual(e,null,"should emit error")
    });
  });
  it("vote functions", function() {
    var ctx;
    var vote = web3.toBigNumber('1000000');
    var account2 = web3.eth.getBalance(accounts[2]);
    var account1 = web3.eth.getBalance(accounts[1]);
    var account0 = web3.eth.getBalance(accounts[0]);
    console.log(account0,account1,account2);
    return Committee.new().then(function(instance) {
      ctx = instance;
      return instance.registerCandidate({from:accounts[2]});
    }).then(function() {
      account0 = web3.eth.getBalance(accounts[0]);
      return ctx.vote(accounts[2],{value:vote,from:accounts[0]});
    }).then(function(tx) {
      console.log(web3.eth.getBalance(accounts[0]));
      var gasUsed = web3.toBigNumber(tx.receipt.gasUsed);
      var gasPrice = web3.eth.getTransaction(tx.tx).gasPrice;
      console.log(gasPrice);
      console.log(gasUsed);
      assert.equal(account0-vote-web3.eth.getBalance(accounts[0])-gasUsed*gasPrice,0,"vote works not correct:voter balance inconsist");
      return ctx.getCandidateVotes(accounts[2]);
    }).then(function(votes){
      assert.equal(votes,vote,"vote works not correct:candidate votes not increased");
      return ctx.revote(accounts[2],accounts[1],{value:vote,from:accounts[0]});
    }).then(function(votes){
      ctx.getCandidateVotes(accounts[1]);
    }).then(function(votes){
      assert.equal(votes,vote,"revote works not correct:candidate votes not increased");
    });
  });
});
