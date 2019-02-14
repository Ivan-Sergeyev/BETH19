App = {
  web3Provider: null,
  contracts: {},
<<<<<<< HEAD
  account: '0x0',
  hasVoted: false,

  // init: function() {
  //   return App.initWeb3();
  // },
  //
  // initWeb3: function() {
  //   // TODO: refactor conditional
  //   if (typeof web3 !== 'undefined') {
  //     // If a web3 instance is already provided by Meta Mask.
  //     App.web3Provider = web3.currentProvider;
  //     web3 = new Web3(web3.currentProvider);
  //   } else {
  //     // Specify default instance if no web3 instance provided
  //     App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
  //     web3 = new Web3(App.web3Provider);
  //   }
  //   return App.initContract();
  // },
  //
  // initContract: function() {
  //   $.getJSON("Favor.json", function(Favor) {
  //     // Instantiate a new truffle contract from the artifact
  //     App.contracts.Favor = TruffleContract(Favor);
  //     // Connect provider to interact with contract
  //     App.contracts.Favor.setProvider(App.web3Provider);
  //
  //     App.listenForEvents();
  //
  //     return App.render();
  //   });
  // },
  //
  // // Listen for events emitted from the contract
  // listenForEvents: function() {
  //   App.contracts.Favor.deployed().then(function(instance) {
  //     // Restart Chrome if you are unable to receive this event
  //     // This is a known issue with Metamask
  //     // https://github.com/MetaMask/metamask-extension/issues/2393
  //
  //   }).then(function() {
  //       console.log("pass render")
  //       // Reload when a new vote is recorded
  //       App.render();
  //     });
  // },
  //
  // render: function() {
  //   var FavorInstance;
  //   // Load account data
  //   web3.eth.getAccounts(function(err, account) {
  //     if (err === null) {
  //       App.account = account[0];
  //     }
  //   });
  //
  //   // Load contract data
  //   App.contracts.Favor.deployed().then(function(instance) {
  //     FavorInstance = instance;
  //   });
  // },
=======

  init: async function() {
    // Load pets.
    $.getJSON('../pets.json', function(data) {
      var petsRow = $('#petsRow');
      var petTemplate = $('#petTemplate');

      for (i = 0; i < data.length; i ++) {
        petTemplate.find('.panel-title').text(data[i].name);
        petTemplate.find('img').attr('src', data[i].picture);
        petTemplate.find('.pet-breed').text(data[i].breed);
        petTemplate.find('.pet-age').text(data[i].age);
        petTemplate.find('.pet-location').text(data[i].location);
        petTemplate.find('.btn-adopt').attr('data-id', data[i].id);

        petsRow.append(petTemplate.html());
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

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('Adoption.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var AdoptionArtifact = data;
      App.contracts.Adoption = TruffleContract(AdoptionArtifact);

      // Set the provider for our contract
      App.contracts.Adoption.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the adopted pets
      return App.markAdopted();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.btn-adopt', App.handleAdopt);
  },

  markAdopted: function(adopters, account) {
    var adoptionInstance;

    App.contracts.Adoption.deployed().then(function(instance) {
      adoptionInstance = instance;

      return adoptionInstance.getAdopters.call();
    }).then(function(adopters) {
      for (i = 0; i < adopters.length; i++) {
        if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));

    var adoptionInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

        // Execute adopt as a transaction by sending account
        return adoptionInstance.adopt(petId, {from: account});
      }).then(function(result) {
        return App.markAdopted();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  }
>>>>>>> 3a2ee3e3c868df510bf1ff0db5e97344eb994797

};

$(function() {
  $(window).load(function() {
    // App.init();
  });
});

window.operateEvents = {
    'click .like': function (e, value, row) {
      alert('You click like action, row: ' + JSON.stringify(row))
    },
    'click .remove': function (e, value, row) {
      alert('You click remove action, row: ' + JSON.stringify(row))
    }
  }

  function operateFormatter(value, row, index) {
    return [
      '<div class="pull-left">',
      '<a href="https://github.com/wenzhixin/' + value + '" target="_blank">' + value + '</a>',
      '</div>',
      '<div class="pull-right">',
      '<a class="like" href="javascript:void(0)" title="Like">',
      '<i class="glyphicon glyphicon-heart"></i>',
      '</a>  ',
      '<a class="remove" href="javascript:void(0)" title="Remove">',
      '<i class="glyphicon glyphicon-remove"></i>',
      '</a>',
      '</div>'
    ].join('')
  }
