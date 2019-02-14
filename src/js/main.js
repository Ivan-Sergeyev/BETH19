App = {
    web3Provider: null,
    favor_contract_instance: null,
    contracts: {},

    init: async function() {
        // init code (loading assets from jsons) goes here
        // ...

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

            // save favor contract instance
            App.contracts.Favor.deployed().then(function(instance) {
                App.favor_contract_instance = instance;
            }).catch(function(err) {
                console.log(err.message);
            });

            // init code (function calls) goes here
            // ...
        });

        return App.bindEvents();
    },

    bindEvents: function() {
        $(document).on('click', '.btn-favor', App.getUserBalance /*this is an example*/);
        // button actions are binded here
        // ...
    },

    getUserBalance: function(callback) {
        App.favor_contract_instance.getUserBalance.call(web3.eth.accounts[0]).then(function(result) {
            console.log("user balance:", result.c[0]);
            callback(result.c[0]);
        }).catch(function(err) {
            console.log(err.message);
        });
    },

    testBuyFVR: function(buy_amount) {
        App.favor_contract_instance.testBuyFVR(
            {from: web3.eth.accounts[0], value: buy_amount}
        ).then(function() {
            App.updateUserBalance();
        });
    },

    getListings: function() {
        ;
    }
};


// main
$(function () {
    $(window).load(function() {
        App.init();

        // todo: get the entire list of open/running favors from the blockchain
    });

    $(window).on('hashchange', function(){
        // On every hash change the render function is called with the new hash.
        // This is how the navigation of our app happens.
        render(decodeURI(window.location.hash));
    });

    // render home page by default
    render('');

    function render(url) {
        // Get the keyword from the url.
        var temp = url.split('/')[0];

        $('.main-content .page').addClass('d-none');

        // call generic update function
        update();

        var map = {
            // The Homepage.
            '': function() {
                renderOpenListings();
            },

            '#DoAFavor': function() {
                renderOpenListings();
            },

            // My open favor requests
            '#MyRequests': function() {
                $('#my_requests').removeClass('d-none');
            },

            // Favors I'm currently doing to someone
            '#MyFavors': function() {
                $('#my_favors').removeClass('d-none');
            },

            // todo: add desc
            '#Apply': function() {
                renderFavorApplication(url.split[1]);
            },

            // Single Products page.
            '#product': function() {
                // Get the index of which product we want to show and call the appropriate function.
                var index = url.split('#product/')[1].trim();
                renderSingleProductPage(index, products);
            }
        };

        if(map[temp]){
            // Execute the needed function depending on the url keyword (stored in temp).
            map[temp]();
        } else {
            // If the keyword isn't listed in the above - render the error page.
            renderErrorPage();
        }
    }

    function renderOpenListings(){
        $('#do_a_favor').removeClass('d-none');
		updateListings();
    }

	function updateListings() {
		$('#do_a_favor').append(renderAllListings());
	}


    function renderErrorPage(){
        console.log("Error: no such Favor!");
    }

    function renderFavorApplication(favorId) {
        if (favorId === undefined) {
            return renderErrorPage();
        }
        $('#apply_for_favor').removeClass('d-none');
    }

    function createQueryHash(filters){
        // Get the filters object, turn it into a string and write it into the hash.
    }

    function update() {
        // set the balance
    }



    function updateBalance(balance) {
        $('#balance').text(balance + ' ');
    }

	function renderAllListings(data){
		data = mockListings;
		for (i = 0; i < data.length; i++) {
			data[i]['id'] = i;
		}
		return data.map(renderListingTemplate);
	}

	function renderListingTemplate(fields) {
		var template = $("#listingTemplate").clone();
		template[0].id = "";
		template.find('.listingTitle').text(fields.title);
		template.find('.listingDescription').text(fields.description);
		template.find('.listingCategory').text(fields.category);
		template.find('.listingCost').text(fields.cost);
		template.find('.listingLocation').text(fields.location);
		template.find('a').attr('href', '#Apply/'+fields.id);
		return template;
	}
});

function updateBalance(balance) {
    $('#balance').text(balance + ' ');
}

mockListings = [
	{"title": "Help writing an essay", "category": 3, description: "My son needs help for a school project" , "location": "Zurich"},
	{"title": "Water my plants", "category": 2, description: "Need someone to water 13 plants" , "location": "Zurich"},
	{"title": "Driver for elderly lady", "category": 1, description: "Grandma cant drive, needs a ride" , "location": "Zurich"},
]
