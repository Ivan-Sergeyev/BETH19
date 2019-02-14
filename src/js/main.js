$(function () {

	// get the entire list of open/running favors from the blockchain

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

			'#Apply': function() {
				renderFavorApplication(url.split[1]);
			},

			// Single Products page.
			'#product': function() {

				// Get the index of which product we want to show and call the appropriate function.
				var index = url.split('#product/')[1].trim();

				renderSingleProductPage(index, products);
			},

		};

		// Execute the needed function depending on the url keyword (stored in temp).
		if(map[temp]){
			map[temp]();
		}
		// If the keyword isn't listed in the above - render the error page.
		else {
			renderErrorPage();
		}

	}


	function renderOpenListings(){
				$('#do_a_favor').removeClass('d-none');
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
		$('#balance').text(getBalance() + ' ');
	}


	function getBalance() {
		return 3;
	}

});
