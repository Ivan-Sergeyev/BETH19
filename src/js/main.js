$(function () {

	$(window).on('hashchange', function(){
		// On every hash change the render function is called with the new hash.
		// This is how the navigation of our app happens.
		render(decodeURI(window.location.hash));
	});


	function render(url) {
		// Get the keyword from the url.
		var temp = url.split('/')[0];

		// Hide whatever page is currently shown.
		$('.main-content .page').addClass('d-none');
		//$('.main-content .page').hide();
		//document.getElementById(temp.slice(1)).removeClass('invisible');

		var map = {

			// The Homepage.
			'': function() {
				$('#do_a_favor').removeClass('d-none');

			},

			'#DoAFavor': function() {
				$('#do_a_favor').removeClass('d-none');

			},

			// My open favor requests
			'#MyRequests': function() {
				$('#my_requests').removeClass('d-none');

			},

			// Favors I'm currently doing to someone
			'#MyFavors': function() {
				$('#my_favors').removeClass('d-none');

			},

			// Single Products page.
			'#product': function() {

				// Get the index of which product we want to show and call the appropriate function.
				var index = url.split('#product/')[1].trim();

				renderSingleProductPage(index, products);
			},

			// Page with filtered products
			'#filter': function() {

				// Grab the string after the '#filter/' keyword. Call the filtering function.
				url = url.split('#filter/')[1].trim();

				// Try and parse the filters object from the query string.
				try {
					filters = JSON.parse(url);
				}
				// If it isn't a valid json, go back to homepage ( the rest of the code won't be executed ).
				catch(err) {
					window.location.hash = '#';
				}

				renderFilterResults(filters, products);
			}

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


	function generateAllProductsHTML(data){
		// Uses Handlebars to create a list of products using the provided data.
		// This function is called only once on page load.
	}

	function renderOpenListings(data){
		// Hides and shows products in the All Products Page depending on the data it recieves.
	}

	function renderSingleProductPage(index, data){
		// Shows the Single Product Page with appropriate data.
	}

	function renderErrorPage(){
		// Shows the error page.
	}

	function createQueryHash(filters){
		// Get the filters object, turn it into a string and write it into the hash.
	}

});
