// NAV PANEL LOGIC
// select panel

var lastpanel = null;

function checkPanelNavigation() {
    if (window.location.hash) {
	var hash = window.location.hash.substr(1);
	if (hash != lastpanel) {
	    triggerNav({ id: hash });
	}
    }
    setTimeout('checkPanelNavigation()', 150)
}

function selectPanel(name) {
    var panelname = 'panel-' + name;
	var panelid = '#' + name;

    if ( $(panelid).exists() ) {
	$(panelid).show();
	$('div.panel:not('+panelid+')').hide();
    } else {
	var panel = $('<div class="panel"></div>').attr('id', panelname);
	$('#content .wrapper').append(panel);
	panel.load('./panel-' + name + '.html', function() {
	    $('div.panel:not('+panelid+')').hide();
	    panel.show();
	});
    }
    
    lastpanel = panelid;
}

// handle nav selection
function selectNav(event) {
    var href = $(this).attr('href');
    var name = 'home';
    if ( href )
	name = href.substring(1);
    
    if (event)
	event.preventDefault();
    
    if ( $(this).hasClass('selected') && window.location.hash == '#' + name)
	return;
    
    window.location.hash = '#' + name;
    
    $(this)
	.parents('ul:first')
	.find('a')
	.removeClass('selected')
	.end()
	.end()
	.addClass('selected');
    
    selectPanel(name);
}

function triggerNav(data) {
    var el = $('#menu .navigation').find('a[href$="' + data.id + '"]').get(0);
    if ( el )
	selectNav.call(el);
    else
	selectPanel(data.id);
}


$(document).ready(function () {
	jQuery.fn.exists = function(){return jQuery(this).length>0;}

	//
	// PANELS
	//
	$('div.panel').hide()
	$('#menu .navigation').find('a[href^="#"]').click(selectNav);
	$("a[rel^='panel']").click(selectNav);

	if (window.location.href.search('place=') > 0) {
		triggerNav({ id : 'forum' });
	} else if (window.location.hash) {
		triggerNav({ id : window.location.hash.substr(1) });
	} else {
		$('ul.navigation a:first').click();
	}


	//
	// Platforms
	//
	$('table.downloads tr').removeClass('selected')

	var dos = $.client.os;
	if ( dos == 'Windows' ) {
		$('tr[class=os-window]').addClass('selected');
	} else if ( dos == 'Mac' ) {
		$('tr[class=os-macosx]').addClass('selected');
	} else if ( dos == 'Linux' ) {
		$('tr[class=os-linux]').addClass('selected');
	}

	//
	// Socials
	//

	// Facebook / Like button
	$('.facebook_like').socialbutton('facebook_like', {
		url: 'https://www.facebook.com/kivysoftware',
		show_faces: false,
		locale: 'en_US',
		button: 'box_count'
	});

	// Google / Google +1 Button
	/**
	$('.google_plusone').socialbutton('google_plusone', {
		url: 'http://kivy.org/',
		lang: 'en-US'
	});
	**/

	// Twitter / Tweet Button
	$('.twitter').socialbutton('twitter', {
		url: 'http://kivy.org/',
		lang: 'en'
	});


	checkPanelNavigation();
});

// STICKY HEADER LOGIC
// When the user scrolls the page, execute myFunction
window.onscroll = function() {myFunction()};

// Get the navbar
var navbar = document.getElementById("headerWrapper");

// Get the offset position of the navbar
if (navbar) { var sticky = navbar.offsetTop; }

// Add the sticky class to the navbar when you reach its scroll position. Remove "sticky" when you leave the scroll position
function myFunction() {
  if (window.pageYOffset >= sticky) {
    navbar.classList.add("sticky")
  } else {
    navbar.classList.remove("sticky");
  }
}

// SUB_PANEL LOGIC
// Function to switch between tabs on click (only active for desktop&tablet view)
function openTab(evt, tabName, sectionName) {
	var i, tabcontent, tablinks;
	var desktopMediaSize = window.matchMedia("(min-width: 768px)")

	// Check media size
	if (checkMediaSize(desktopMediaSize)) {
		
		// Get all elements with class="tab_content" in same section and hide
		tabcontent = document.getElementsByClassName("tab_content");

		for (i = 0; i < tabcontent.length; i++) {
			if (tabcontent[i].classList.contains(sectionName)) {
				tabcontent[i].style.display = "none";
			}
		}

		// Get all elements with class="tablinks" and remove the underline styling
		tablinks = document.getElementsByClassName("tablinks");				
		for (i = 0; i < tablinks.length; i++) {
			if (tablinks[i].classList.contains(sectionName)){
				tablinks[i].className = tablinks[i].className.replace(" underline_active", "");						
			}
		}

		// Show the current tab, and add underline to the button that opened the tab (handle download tab use case)
		document.getElementById(tabName).style.display = "flex";
		var downloadtabs;
		if (sectionName == 'download') {
			downloadtabs = document.getElementsByClassName("tablinks");
			for (i=0; i < downloadtabs.length; i++) {
				if (downloadtabs[i].classList.contains(tabName)) {
					downloadtabs[i].className += " underline_active"
				}
			}
		} else {
			evt.currentTarget.className += " underline_active";		
		}
	}
}

// Get all defaultOpen elements and click to activate
var defaults = document.getElementsByClassName("defaultOpen");
for (i = 0; i < defaults.length; i++) {
		defaults[i].click();
}

// ** MOBILE VIEW **
// Expand and collapse hamburger menu
function hamburgerMenu() {
	var x = document.getElementById("nav_links");
	if (x.style.display === "block") {
		x.style.display = "none";
	} else {
		x.style.display = "block";
	}
}

// Function to check for desktop vs. mobile view
function checkMediaSize(x) {
	if (x.matches) {
		return true;
	} else {
		return false;
	}
}