const NULL_ADDR = '0x0000000000000000000000000000000000000000';

App = {
    // ==================== member variables ====================

    web3Provider: null,
    contracts: {},
    billboard: [],

    // mock_billboard: [
    //     {
    //         "id": 242,
    //         "title": "Help writing an essay",
    //         "category": 3,
    //         "description": "My son needs help for a school project",
    //         "location": "Zurich",
    //         "requester_addr": "0x1324",
    //         "performer_addr": "0x3212"
    //     },
    //     {
    //         "id": 211,
    //         "title": "Water my plants",
    //         "category": 2,
    //         "description": "Need someone to water 13 plants",
    //         "location": "Zurich",
    //         "requester_addr": "0x3212",
    //         "performer_addr": "0x0000"
    //     },
    //     {
    //         "id": 219,
    //         "title": "Driver for elderly lady",
    //         "category": 1,
    //         "description": "Grandma can't drive, needs a ride",
    //         "location": "Zurich",
    //         "requester_addr": "0x3242",
    //         "performer_addr": "0x0000"
    //     }
    // ],

    defaultErrorHandler: function(err) {
        console.log(err.message);
    },

    // ==================== init ====================

    // initializes App
    init: async function() {
        console.log("in App.init()");
        // init code (loading assets from jsons) goes here
        return await App.initWeb3();
    },

    // initializes web3
    initWeb3: async function() {
        console.log("in App.initWeb3()");
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

        // init contract
        await App.initContract();

        // bind button presses
        // todo

        // example:
        // $(document).on('click', '.btn-favor', App.getUserBalance);
        // ...
        // function createFavorRequest(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 favor_id) {
        // function createFavorOffer(uint _cost_fvr, bytes32 _title, bytes32 _location, bytes32 _description, uint _category) external returns (bytes32 favor_id) {
        // function acceptFavorRequest(bytes32 _favor_id) external {
        // function acceptFavorOffer(bytes32 _favor_id) external {
        // function requestAbortFavor(bytes32 _favor_id) external {
        // function requestCompleteFavor(bytes32 _favor_id) external {
    },

    // initializes FavorExchange contract
    initContract: async function() {
        console.log("in App.initContract()");
        $.getJSON('FavorExchange.json', function(data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract
            App.contracts.FavorExchange = TruffleContract(data);

            // Set the provider for our contract
            App.contracts.FavorExchange.setProvider(App.web3Provider);

            App.contracts.FavorExchange.deployed().then(function(instance) {
                // -------------------- bind events --------------------

                // bind event BalanceChanged(address user_addr)
                console.log("bind event BalanceChanged");
                instance.BalanceChanged().watch(function(error, result) {
                    console.log("on BalanceChanged");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onBalanceChanged(result.args.user_addr);
                    }
                });

                // bind event FavorCreated(bytes32 favor_id)
                console.log("bind event FavorCreated");
                instance.FavorCreated().watch(function(error, result) {
                    console.log("on FavorCreated");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorCreated(result.args.favor_id);
                    }
                });

                // bind event FavorAccepted(bytes32 favor_id)
                console.log("bind event FavorAccepted");
                instance.FavorAccepted().watch(function(error, result) {
                    console.log("on FavorAccepted");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorAccepted(result.args.favor_id);
                    }
                });

                // bind event FavorVoteCancel(bytes32 favor_id)
                console.log("bind event FavorVoteCancel");
                instance.FavorVoteCancel().watch(function(error, result) {
                    console.log("on FavorVoteCancel");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorVoteCancel(result.args.favor_id);
                    }
                });

                // bind event FavorCancel(bytes32 favor_id)
                console.log("bind event FavorCancel");
                instance.FavorCancel().watch(function(error, result) {
                    console.log("on FavorCancel");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorCancel(result.args.favor_id);
                    }
                });

                // bind event FavorVoteDone(bytes32 favor_id)
                console.log("bind event FavorVoteDone");
                instance.FavorVoteDone().watch(function(error, result) {
                    console.log("on FavorVoteDone");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorVoteDone(result.args.favor_id);
                    }
                });

                // bind event FavorDone(bytes32 favor_id)
                console.log("bind event FavorDone");
                instance.FavorDone().watch(function(error, result) {
                    console.log("on FavorDone");
                    if (error) {
                        console.log(error);
                    } else {
                        App.onFavorDone(result.args.favor_id);
                    }
                });

                // -------------------- set up page elements --------------------

                // retrieve and display balance
                App.onBalanceChanged(web3.eth.accounts[0]);

                // retrieve and display billboard
                App.onGetBillboard();

            }).catch(App.defaultErrorHandler);
        });
    },

    // -------------------- callbacks --------------------

    onBalanceChanged: function(user_addr) {
        console.log("in App.onBalanceChanged(", user_addr, ")");
        if (user_addr == web3.eth.accounts[0]) {
            console.log("get balance");
            App.contracts.FavorExchange.deployed().then(function(instance) {
                return instance.getUserBalance.call();
            }).then(function(result) {
                console.log("user balance:", result.c[0]);
                App.uiRenderBalance(result.c[0]);
            }).catch(App.defaultErrorHandler);
        }
    },

    onFavorAccepted: function(favor_id) {
        console.log("in App.onFavorAccepted(", favor_id, ")");
        console.log("Not implemented");
    },

    onFavorCancel: function (favor_id) {
        console.log("in App.onFavorCancel(", favor_id, ")");
        console.log("Not implemented");
    },

    onFavorVoteCancel: function (favor_id) {
        console.log("in App.onFavorVoteCancel(", favor_id, ")");
        console.log("Not implemented");
    },

    onFavorDone: function(favor_id) {
        console.log("in App.onFavorDone(", favor_id, ")");
        console.log("Not implemented");
    },

    onFavorVoteDone: function(favor_id) {
        console.log("in App.onFavorVoteDone(", favor_id, ")");
        console.log("Not implemented");
    },

    onFavorCreated: function(favor_id) {
        console.log("in App.onFavorCreated(", favor_id, ")");
        console.log("Not implemented");
    },

    // -------------------- button functions --------------------

    testBuyToken: function(buy_amount) {
        console.log("in App.testBuyToken(", buy_amount, ")");
        App.contracts.FavorExchange.deployed().then(function(instance) {
            console.log(instance);
            instance.testBuyToken({from: web3.eth.accounts[0], value: buy_amount});
        }).catch(App.defaultErrorHandler);
    },

    // ---------- billboard population ----------

    testPopulateBillboard: function() {
        console.log("in App.testPopulateBillboard()");
        App.contracts.FavorExchange.deployed().then(function(instance) {
            return instance.testPopulateBillboard(web3.eth.accounts[0]);
        }).then(function(result) {
            App.onGetBillboard();
        }).catch(App.defaultErrorHandler);
    },

    onGetBillboard: function() {
        console.log("in App.onGetBillboard()");
        var favor_exchange_instance;
        App.billboard = [];

        App.contracts.FavorExchange.deployed().then(function(instance) {
            favor_exchange_instance = instance;
            return favor_exchange_instance.getFavorsHeadId.call();
        }).then(function(result) {
            console.log("result:", result);
            App.addFavorToBillboard(result);
        }).catch(App.defaultErrorHandler);
    },

    addFavorToBillboard: function(favor_id) {
        console.log("in App.addFavorToBillboard(", favor_id, ")");

        App.contracts.FavorExchange.deployed().then(function(instance) {
            return instance.getFavorInfo.call(favor_id);
        }).then(function(result) {
            var favor = App.getFavorJSON(result);
            console.log("considering favor:", favor);
            favor_nonempty = !(App.isFavorEmpty(favor));

            if(favor_nonempty) {
                App.billboard.push(favor);
            }

            if(favor_nonempty && (favor.next_favor_id != favor_id)) {
                App.addFavorToBillboard(favor.next_favor_id);
            } else {
                console.log("complete billboard:", App.billboard);
                App.uiRenderAllFavors();
            }
        }).catch(App.defaultErrorHandler);
    },

    isFavorEmpty: function(favor) {
        return (favor.client_addr == NULL_ADDR) && (favor.provider_addr == NULL_ADDR);
    },

    getFavorJSON: function(raw_data) {
        return {
            "prev_favor_id" : raw_data[0],
            "next_favor_id" : raw_data[1],
            "client_addr" : raw_data[2],
            "provider_addr" : raw_data[3],
            "cost" : raw_data[4].c[0],
            "title" : raw_data[5],
            "location" : raw_data[6],
            "description" : raw_data[7],
            "category" : raw_data[8].c[0]
        };
    },

    // -------------------- UI --------------------

    uiRenderBalance: function(balance) {
        $('#balance').text(balance + ' ');
    },

    uiRenderAllFavors: function() {
        // todo: separate open requests, open offers and active favors and use corresponding templates?
        data = App.billboard;
        return data.map(App.fillRequestTemplate);
    },

    uiRenderOpenFavors: function() {
        $('#do_a_favor').removeClass('d-none');
        App.uiRenderFavors();
    },

    uiRenderRequests: function() {
        $('#my_requests').removeClass('d-none');
        $('#my_requests').append(App.getUserRequests().map(App.fillRequestTemplate));
    },

    getUserRequests: function() {
        // get a list of all favors requested by the user
        // todo: logic
        var userRequests = App.billboard.slice(0,2);
        return userRequests;
    },

    uiTransactApplication: function(favorId) {
        // todo
        alert('Your transaction has been completed');
    },

    uiTransactAccept: function(favorId) {
        // todo
        alert('Your transaction has been completed');
    },

    uiRenderFavors: function() {
        $('#do_a_favor').append(App.uiRenderAllFavors());
    },

    uiRenderErrorPage: function() {
        // todo
    },

    uiRenderFavorApplication: function(favorId, data) {
        console.log("Rendering favor " + favorId);
        if (favorId === undefined || data === undefined) {
            console.log("Error: no such Favor!");
            return renderErrorPage();
        }

        $('#apply_for_favor').removeClass('d-none');
        $('#apply_for_favor').append(renderApplicationTemplate(data.filter(
            fav => {return fav.id == favorId;})[0]
        ));
    },

    createQueryHash: function(filters) {
        // todo: get the filters object, turn it into a string and write it into the hash.
    },

    fillFavorTemplate: function(fields) {
        var template = $("#favorTemplate").clone();
        template[0].id = "";
        template.removeClass('d-none');
        template.find('.favorTitle').text(fields.title);
        template.find('.favorDescription').text(fields.description);
        template.find('.favorCategory').text(fields.category);
        template.find('.favorCost').text(fields.cost);
        template.find('.favorLocation').text(fields.location);
        template.find('a').attr('href', '#Apply/'+fields.id);
        return template;
    },

    fillOfferTemplate: function(fields) {
        var template = $("#favorApplicationTemplate").clone();
        template[0].id = "";
        template.removeClass('d-none');
        template.find('.favorTitle').text(fields.title);
        template.find('.favorDescription').text(fields.description);
        template.find('.favorCategory').text(fields.category);
        template.find('.favorCost').text(fields.cost);
        template.find('.favorLocation').text(fields.location);
        template.find('a').attr('href', '#TransactApplication/'+fields.id);
        return template;
    },

    fillRequestTemplate: function(fields) {
        var template = $("#RequestTemplate").clone();
        template[0].id = "";
        template.removeClass('d-none');
        template.find('.favorTitle').text(fields.title);
        template.find('.favorDescription').text(fields.description);
        template.find('.favorCategory').text(fields.category);
        template.find('.favorCost').text(fields.cost);
        template.find('.favorLocation').text(fields.location);
        template.find('.performerAddress').text(fields.performer_addr);
        template.find('a').attr('href', '#TransactAccept/'+fields.id);
        // TODO: change 0x0000 to the ethereum NULL address
        if (fields.performer_addr != '0x0000') {
            template.find('.favor_available').removeClass('d-none');
            template.find('.favor_pending').addClass('d-none');
        }
        return template;
    }
};


// main
$(function () {
    $(window).load(function() {
        App.init();
    });

    $(window).on('hashchange', function() {
        // on every hash change the render function is called with the new hash.
        // This is how the navigation of our app happens.
        render(decodeURI(window.location.hash));
    });

    // render home page by default
    render('');

    function render(url) {
        // Get the keyword from the url.
        var temp = url.split('/')[0];

        $('.main-content .page').addClass('d-none');

        var map = {
            // The Homepage.
            '': function() {
                App.uiRenderOpenFavors();
            },

            '#DoAFavor': function() {
                App.uiRenderOpenFavors();
            },

            // My open favor requests
            '#MyRequests': function() {
                App.uiRenderRequests();
            },

            // Favors I'm currently doing to someone
            '#MyFavors': function() {
                $('#my_favors').removeClass('d-none');
            },

            // todo: add desc
            '#Apply': function() {
                // todo: real billboard
                App.uiRenderFavorApplication(url.split('/')[1], App.billboard);
            },

            // todo: add desc
            '#TransactApplication': function() {
                App.uiTransactApplication(url.split('/')[1], App.billboard);
            },

            // todo: add desc
            '#TransactAccept': function() {
                App.uiTransactAccept(url.split('/')[1], App.billboard);
            }
        };

        if(map[temp]) {
            // Execute the needed function depending on the url keyword (stored in temp).
            map[temp]();
        } else {
            // If the keyword isn't listed in the above - render the error page.
            App.uiRenderErrorPage();
        }
    }
});
