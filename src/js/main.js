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

            App.contracts.Favor.deployed().then(function(instance) {
                App.favor_contract_instance = instance;

                // -------------------- bind events --------------------

                // bind event BalanceChanged(address user_addr);
                App.favor_contract_instance.BalanceChanged().watch(function(error, result) {
                    console.log("On BalanceChanged");
                    if (error) {
                        console.log(error);
                    } else {
                        BalanceChangedCallback(result.args.user_addr);
                    }
                });

                // bind event ListingAccepted(bytes32 listing_idx);
                App.favor_contract_instance.ListingAccepted().watch(function(error, result) {
                    console.log("On ListingAccepted");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingAcceptedCallback(listing_idx);
                    }
                });

                // bind event ListingAborted(bytes32 listing_idx);
                App.favor_contract_instance.ListingAborted().watch(function(error, result) {
                    console.log("On ListingAborted");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingAbortedCallback(listing_idx);
                    }
                });

                // bind event ListingAbortRequest(bytes32 listing_idx);
                App.favor_contract_instance.ListingAbortRequest().watch(function(error, result) {
                    console.log("On ListingAbortRequest");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingAbortRequestCallback(listing_idx);
                    }
                });

                // bind event ListingCompleted(bytes32 listing_idx);
                App.favor_contract_instance.ListingCompleted().watch(function(error, result) {
                    console.log("On ListingCompleted");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingCompletedCallback(listing_idx);
                    }
                });

                // bind event ListingCompleteRequest(bytes32 listing_idx);
                App.favor_contract_instance.ListingCompleteRequest().watch(function(error, result) {
                    console.log("On ListingCompleteRequest");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingCompleteRequestCallback(listing_idx);
                    }
                });

                // bind event ListingCreated(bytes32 listing_idx);
                App.favor_contract_instance.ListingCreated().watch(function(error, result) {
                    console.log("On ListingCreated");
                    if (error) {
                        console.log(error);
                    } else {
                        ListingCreatedCallback(listing_idx);
                    }
                });

                // -------------------- bind button presses --------------------
                // example:
                // $(document).on('click', '.btn-favor', App.getUserBalance);
                // ...
                // function createListingRequest(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_idx) {
                // function createListingOffer(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 listing_idx) {
                // function acceptListingRequest(bytes32 _listing_idx) external {
                // function acceptListingOffer(bytes32 _listing_idx) external {
                // function requestAbortListing(bytes32 _listing_idx) external {
                // function requestCompleteListing(bytes32 _listing_idx) external {

                // -------------------- retrieve listings --------------------
                // function getListingInfo(bytes32 _listing_idx) external view returns (bytes32, bytes32, address, address, uint, bytes32, bytes32, bytes32, uint) {
                getListings: function() {
                    App.favor_contract_instance.getListingsHeadIdx.call().then(function(result) {

                    });
                };

            }).catch(function(err) {
                console.log(err.message);
            });
        });
    },

    BalanceChangedCallback: function(user_addr) {
        if (user_addr == web3.eth.accounts[0]) {
            console.log("Get balance");
            App.favor_contract_instance.getUserBalance.call().then(function(result) {
                console.log("user balance:", result.c[0]);
                $('#balance').text(result.c[0] + ' ');
            }).catch(function(err) {
                console.log(err.message);
            });
        }
    },

    ListingAcceptedCallback: function(listing_idx) {
        console.log("Not implemented");
    },

    ListingAbortedCallback: function (listing_idx) {
        console.log("Not implemented");
    },

    ListingAbortRequestCallback: function (listing_idx) {
        console.log("Not implemented");
    },

    ListingCompletedCallback: function(listing_idx) {
        console.log("Not implemented");
    },

    ListingCompleteRequestCallback: function(listing_idx) {
        console.log("Not implemented");
    },

    ListingCreatedCallback: function(listing_idx) {
        console.log("Not implemented");
    },

    testBuyFVR: function(buy_amount) {
        App.favor_contract_instance.testBuyFVR({from: web3.eth.accounts[0], value: buy_amount});
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
                renderRequests();
            },

            // Favors I'm currently doing to someone
            '#MyFavors': function() {
                $('#my_favors').removeClass('d-none');
            },

            // todo: add desc
            '#Apply': function() {
                // TODO: real listings
                renderFavorApplication(url.split('/')[1], mockListings);
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

    function renderRequests() {
        $('#my_requests').removeClass('d-none');
        $('#my_requests').append(getUserRequests().map(renderRequestTemplate));
    }

    function getUserRequests() {
        // get a list of all listings that have been requested by the user
        // TODO: logic
        var userRequests = mockListings.slice(0,2);
        return userRequests;
    }

    function updateListings() {
        $('#do_a_favor').append(renderAllListings());
    }

    function renderErrorPage(){
    }

    function renderFavorApplication(favorId, data) {
        console.log("Rendering favor " + favorId);
        if (favorId === undefined || data === undefined) {
            console.log("Error: no such Favor!");
            return renderErrorPage();
        }

        $('#apply_for_favor').removeClass('d-none');
        $('#apply_for_favor').append(renderListingTemplate(data[favorId]));
    }

    function createQueryHash(filters){
        // Get the filters object, turn it into a string and write it into the hash.
    }

    function update() {
        // set the balance
    }

    function renderAllListings(data){
        data = mockListings;
        for (i = 0; i < data.length; i++) {
            data[i]['id'] = i;
        }
        return data.map(renderListingTemplate);
    }

    function renderAllListings(data){
        // TODO: logic
        data = mockListings;
        for (i = 0; i < data.length; i++) {
            data[i]['id'] = i;
        }
        return data.map(renderListingTemplate);
    }

    function renderListingTemplate(fields) {
        var template = $("#listingTemplate").clone();
        template[0].id = "";
        template.removeClass('d-none');
        template.find('.listingTitle').text(fields.title);
        template.find('.listingDescription').text(fields.description);
        template.find('.listingCategory').text(fields.category);
        template.find('.listingCost').text(fields.cost);
        template.find('.listingLocation').text(fields.location);
        template.find('a').attr('href', '#Apply/'+fields.id);
        return template;
    }

    function renderRequestTemplate(fields) {
        var template = $("#RequestTemplate").clone();
        template[0].id = "";
        template.removeClass('d-none');
        template.find('.listingTitle').text(fields.title);
        template.find('.listingDescription').text(fields.description);
        template.find('.listingCategory').text(fields.category);
        template.find('.listingCost').text(fields.cost);
        template.find('.listingLocation').text(fields.location);
        template.find('a').attr('href', '#Apply/'+fields.id);
        // TODO: change 0x0000 to the ethereum NULL address
        if (fields.performer_addr != '0x0000') {
            template.find('.favor_available').removeClass('d-none');
            template.find('.favor_pending').addClass('d-none');
        }
        return template;
    }
});

function updateBalance(balance) {
    $('#balance').text(balance + ' ');
}

mockListings = [
    {"title": "Help writing an essay", "category": 3, description: "My son needs help for a school project" , "location": "Zurich", "requester_addr": "0x1324", "performer_addr": "0x3212"},
    {"title": "Water my plants", "category": 2, description: "Need someone to water 13 plants" , "location": "Zurich", "requester_addr": "0x3212", "performer_addr": "0x0000"},
    {"title": "Driver for elderly lady", "category": 1, description: "Grandma can't drive, needs a ride" , "location": "Zurich", "requester_addr": "0x3242", "performer_addr": "0x0000"},
]
