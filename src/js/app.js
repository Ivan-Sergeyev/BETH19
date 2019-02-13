App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    $.getJSON('../favors.json', function(data) {
      var favorsRow = $('#favorsRow');
      var favorTemplate = $('#favorTemplate');

      for (i = 0; i < data.length; i ++) {
        favorTemplate.find('.panel-title').text(data[i].name);
        favorTemplate.find('img').attr('src', data[i].picture);
        favorTemplate.find('.favor-location').text(data[i].location);
        favorTemplate.find('.btn-adopt').attr('data-id', data[i].id);

        favorsRow.append(favorTemplate.html());
      }
    });

    return await App.initWeb3();
  },

  initWeb3: async function() {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    console.log("initWeb3 works");

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('Favor.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var FavorArtifact = data;
      App.contracts.Favor = TruffleContract(FavorArtifact);

      // Set the provider for our contract
      App.contracts.Favor.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the adopted favors
      console.log("jsonReady1");
    }).then(function() {
          console.log("jsonReady2");
          return App.bindEvents();
        }).catch(function(err) {
          console.log(err.message);
        });
  },

  bindEvents: function() {
    $(document).on('click', '.btn-adopt', App.handleSomething);
    console.log("bindEvents works");
  },

  updateView: function(account) {
    var favorInstance;
    console.log("updateView works");

    App.contracts.Favor.deployed().then(function(instance) {
      favorInstance = instance;
    }).then(function() {
      console.log("works2");
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleSomething: function(event) {
    // what does this do?
    // event.preventDefault();

    // var favorId = parseInt($(event.target).data('id'));

    var favorInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      console.log(account);


      App.contracts.Favor.deployed().then(function(instance) {
        favorInstance = instance;

        // Execute adopt as a transaction by sending account
        // return favorInstance.adopt(favorId, {from: account});
        console.log("works3");

      }).then(function(result) {
        return App.updateView();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  }

};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
