App = {
    web3Provider: null,
    contracts: {},

    init: async function() {
        // Load pets.
        $.getJSON('../tasks.json', function(data) {
          var listingsRow = $('#listingsRow');
          var listingTemplate = $('#listingTemplate');

          for (i = 0; i < data.length; i ++) {
            listingTemplate.find('.taskTitle').text(data[i].title);
            listingTemplate.find('taskPrice').innerHTML = data[i].price;
            listingTemplate.find('.taskDescription').text(data[i].description);
            listingTemplate.find('.taskLocation').text(data[i].location);
            listingTemplate.find('.btn-favor').attr('data-id', data[i].id);
            listingsRow.append(listingTemplate.html());
          }
        });
        return await App.initWeb3();
    },

    initWeb3: async function() {
        if (window.ethereum) {
            // Modern dapp browsers
            App.web3Provider = window.ethereum;
            try {
                // Request account access
                await window.ethereum.enable();
            } catch (error) {
                // User denied account access
                console.error("User denied account access")
            }
        } else if (window.web3) {
            // Legacy dapp browsers
            App.web3Provider = window.web3.currentProvider;
        } else {
            // If no injected web3 instance is detected, fall back to Ganache
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        }
        web3 = new Web3(App.web3Provider);

        return App.initContract();
    },

    initContract: function() {
        $.getJSON('Favor.json', function(data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract
            var FavorArtifact = data;
            App.contracts.Favor = TruffleContract(FavorArtifact);

            // Set the provider for our contract
            App.contracts.Favor.setProvider(App.web3Provider);

            // // Use our contract to retrieve and mark the adopted pets
            return App.getUserBalance();
        });

        return App.bindEvents();
    },

    bindEvents: function() {
        $(document).on('click', '.btn-favor', App.getUserBalance);
    },

    getUserBalance: function() {
        var favorInstance;
        web3.eth.getAccounts(function(error, accounts) {
            if (error) {
                console.log(error);
            }
            App.contracts.Favor.deployed().then(function(instance) {
                favorInstance = instance;
                return favorInstance.getUserBalance.call(accounts[0]);
            }).then(function(result) {
                console.log(result);
                console.log(result.c[0]);
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
