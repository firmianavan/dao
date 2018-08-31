var Committee = artifacts.require("./Committee.sol");

contract('Committee', function(accounts) {
  // console.log(accounts);
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
    var step = 0;
    return Committee.new().then(function(instance) {
      ctx = instance;
      step++;
      return instance.registerCandidate({from:accounts[2]});
    }).then(function() {
      step++;
      account0 = web3.eth.getBalance(accounts[0]);
      return ctx.vote(accounts[2],{value:vote,from:accounts[0]});
    }).then(function(tx) {
      step++;
      var gasUsed = web3.toBigNumber(tx.receipt.gasUsed);
      var gasPrice = web3.eth.getTransaction(tx.tx).gasPrice;
      assert.equal(account0.sub(gasPrice.mul(gasUsed)).toString(),web3.eth.getBalance(accounts[0]).add(vote).toString(),"vote works not correct:voter balance inconsist");
      return ctx.getCandidateVotes(accounts[2]);
    }).then(function(votes){
      step++;
      assert.equal(votes.valueOf(),vote.valueOf(),"vote works not correct:candidate votes not increased");
      return ctx.revote(accounts[2],accounts[1],vote,{from:accounts[0]});
    }).then(function(){
      step++;
      return ctx.getCandidateVotes(accounts[1]);
    }).then(function(votes){
      step++;
      assert.equal(votes.valueOf(),vote.valueOf(),"revote works not correct:candidate votes not increased");
      return ctx.revote(accounts[1],accounts[0],vote.add(1),{from:accounts[0]});
    }).then(function(){
      assert("revote works not correct: expect error not received: revote more than you own");
    }).catch((err)=>{
      assert(err.message.includes("revert"),`revote works not correct: expect error revert, received ${err} instead`);
      assert.equal(step,6,"error occurs in the middle")
    });
  });

  it("withdraw functions", function() {
    var ctx;
    var vote = web3.toBigNumber('1000000');
    var account2 = web3.eth.getBalance(accounts[2]);
    var account1 = web3.eth.getBalance(accounts[1]);
    var account0 = web3.eth.getBalance(accounts[0]);
    var step = 0;
    return Committee.new().then(function(instance) {
      ctx = instance;
      step++;
      return instance.registerCandidate({from:accounts[2]});
    }).then(function() {
      step++;
      account0 = web3.eth.getBalance(accounts[0]);
      return ctx.vote(accounts[2],{value:vote,from:accounts[0]});
    }).then(function(tx) {
      step++;
      var gasUsed = web3.toBigNumber(tx.receipt.gasUsed);
      var gasPrice = web3.eth.getTransaction(tx.tx).gasPrice;
      assert.equal(account0.sub(gasPrice.mul(gasUsed)).toString(),web3.eth.getBalance(accounts[0]).add(vote).toString(),"vote works not correct:voter balance inconsist");
      return ctx.setWithdrawRound(1,{from:accounts[0]});
    }).then(function() {
      account0 = web3.eth.getBalance(accounts[0]);
      return ctx.withdraw(accounts[2],vote,{from:accounts[0]});
    }).then(function(tx) {
      step++;
      var gasUsed = web3.toBigNumber(tx.receipt.gasUsed);
      var gasPrice = web3.eth.getTransaction(tx.tx).gasPrice;
      assert.equal(account0.sub(gasPrice.mul(gasUsed)).toString(),web3.eth.getBalance(accounts[0]).sub(vote).toString(),"withdraw works not correct:withdraw balance inconsist");
    });
  });

  it("end round functions", function() {
    var ctx;
    return Committee.new().then(function(instance) {
      ctx = instance;
      return instance.registerCandidate({from:accounts[2]});
    }).then(function() {
      return ctx.registerCandidate({from:accounts[1]});
    }).then(function() {
      return ctx.registerCandidate({from:accounts[0]});
    }).then(function() {
      return ctx.setRoundSpan(2,{from:accounts[0]});
    }).then(function() {
      return ctx.setMemberCnt(2,{from:accounts[0]});
    }).then(function() {
      return ctx.vote(accounts[2],{value:300000,from:accounts[0]});
    }).then(function() {
      return ctx.vote(accounts[1],{value:200000,from:accounts[0]});
    }).then(function() {
      return ctx.vote(accounts[0],{value:100000,from:accounts[0]});
    }).then(function() {
      return ctx.getMembers({from:accounts[0]});
      // return ctx.test();
    }).then(function(result) {
      // console.log(result.logs[0].args);
      var members = result.logs[0].args._members;
      assert.equal(members[0],accounts[2],"caculating voted member wrong");
      assert.equal(members[1],accounts[1],"caculating voted member wrong");
      // console.log(cnt);
      // assert.equal(account0.sub(gasPrice.mul(gasUsed)).toString(),web3.eth.getBalance(accounts[0]).add(vote).toString(),"vote works not correct:voter balance inconsist");
      // return ctx.setWithdrawRound(1,{from:account0});
    });
  });
});
