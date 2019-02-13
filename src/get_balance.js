getBalance = function() {
  var contractInstance;

  web3.eth.getAccounts(function(error, accounts) {
    if (error) {
      console.log(error);
    }

    var account = accounts[0];
    App.contracts.Master.deployed().then(function(instance) {
      contractInstance = instance;
    });

  });
  
  return instance.getBalance.call();
}


