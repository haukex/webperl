"use strict"; /* DO NOT EDIT THIS LINE! begin_webperl6_patch */

/***** NOTICE: This is part of the experimental WebPerl Perl 6 support.
 * This file (webperl6.js) is currently patched into webperl.js by 6init.pl.
 * There is currently a fair amount of duplication between the following code
 * and webperl.js that should probably be reduced.
 * This file should eventually be merged permanently into webperl.js.
 */

/** ***** WebPerl - http://webperl.zero-g.net *****
 * 
 * Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
 * at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
 * Berlin, Germany, http://www.igb-berlin.de
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl 5 itself: either the GNU General Public
 * License as published by the Free Software Foundation (either version 1,
 * or, at your option, any later version), or the "Artistic License" which
 * comes with Perl 5.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the licenses for details.
 * 
 * You should have received a copy of the licenses along with this program.
 * If not, see http://perldoc.perl.org/index-licence.html
**/

// I'm using "Raku" because the Hamming distance from Perl <-> Perl6 is too small for me,
// it's too much of a risk for typos since webperl.js also provides the "Perl" object.
// But the following functions are currently available on both the Raku.* and Perl6.* objects:
//   .init(), .eval(), .addStateChangeListener(), .makeOutputTextarea()
// but everything else, such as Raku.state or Raku.output, needs to go via the Raku object.
var Raku = {
	state: "Uninitialized",  // user may read (only!) this
	// internal variables:
	stdout_buf: "", stderr_buf: "", // for our default Raku.output implementation
};
var Perl6 = {};

Raku.changeState = function (newState) {
	if (Raku.state==newState) return;
	var oldState = Raku.state;
	Raku.state = newState;
	for( var i=0 ; i<Raku.stateChangeListeners.length ; i++ )
		Raku.stateChangeListeners[i](oldState,newState);
};
Raku.stateChangeListeners = [ function (from,to) {
	console.debug("Raku: state changed from "+from+" to "+to);
} ];
Raku.addStateChangeListener = Perl6.addStateChangeListener = function (handler) {
	Raku.stateChangeListeners.push(handler);
};

// chan: 1=STDOUT, 2=STDERR
// implementations are free to ignore the "chan" argument if they want to merge the two streams
Raku.output = function (str,chan) { // can be overridden by the user
	var buf = chan==2 ? 'stderr_buf' : 'stdout_buf';
	Raku[buf] += str;
	var pos = Raku[buf].indexOf("\n");
	while (pos>-1) {
		console.log( chan==2?"STDERR":"STDOUT", Raku[buf].slice(0,pos) );
		Raku[buf] = Raku[buf].slice(pos+1);
		pos = Raku[buf].indexOf("\n");
	}
};

Raku.makeOutputTextarea = Perl6.makeOutputTextarea = function (id) {
	var ta = document.createElement('textarea');
	if (id) ta.id = id;
	ta.rows = 24; ta.cols = 80;
	ta.setAttribute("readonly",true);
	Raku.output = function (str) {
		ta.value = ta.value + str;
		ta.scrollTop = ta.scrollHeight;
	};
	return ta;
};

Raku.init = Perl6.init = function (readyCallback) {
	if (Raku.state != "Uninitialized")
		throw "Raku: can't call init in state "+Raku.state;
	Raku.changeState("Initializing");
	var baseurl = Perl.Util.baseurl(getScriptURL()); // from webperl.js
	
	// NOTE that NQP_STDOUT currently gets handed HTML,
	// so we jump through some hoops to decode it here:
	var decode_div = document.createElement('div');
	window.NQP_STDOUT = function (str) {
		str = str.replace(/[\<\>]/g,''); // declaw unexpected tags
		decode_div.innerHTML = str;
		str = decode_div.textContent;
		decode_div.textContent = '';
		Raku.output(str,1);
	};
	
	console.debug("Raku: Fetching Perl6...");
	var script = document.createElement('script');
	script.async = true; script.defer = true;
	// Order is important here: 1. Add to DOM, 2. set onload, 3. set src
	document.getElementsByTagName('head')[0].appendChild(script);
	script.onload = function () {
		Raku.eval = Perl6.eval = window.evalP6;
		Raku.changeState("Ready");
		if (readyCallback) readyCallback();
	};
	script.src = baseurl+"/perl6.js";
}

window.addEventListener("load", function () {
	var scripts = [];
	var script_src;
	document.querySelectorAll("script[type='text/perl6'],script[type='text/raku']")
		.forEach(function (el) {
			if (el.src) {
				if (script_src || scripts.length)
					console.error('Only a single Perl6 script may be loaded via "script src=", ignoring others');
				else
					script_src = el.src;
			}
			else {
				if (script_src)
					console.error('Only a single Perl6 script may be loaded via "script src=", ignoring others');
				else
					scripts.push(el.innerHTML);
			}
		});
	if (script_src) {
		console.debug("Raku: Found a script with src, fetching and running...", script_src);
		var xhr = new XMLHttpRequest();
		xhr.addEventListener("load", function () {
			var code = this.responseText;
			Raku.init(function () { Raku.eval(code); });
		});
		xhr.open("GET", script_src);
		xhr.send();
	}
	else if (scripts.length) {
		console.debug("Raku: Found",scripts.length,"embedded script(s), autorunning...");
		var code = scripts.join(";\n");
		Raku.init(function () { Raku.eval(code); });
	}
	else console.debug("Raku: No embedded scripts");
});

/* DO NOT EDIT THIS LINE! end_webperl6_patch */
