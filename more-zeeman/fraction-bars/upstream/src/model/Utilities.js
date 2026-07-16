// Copyright University of Massachusetts Dartmouth 2013
//
// Designed and built by James P. Burke and Jason Orrill
// Modified and developed by Hakan Sandir
//
// This Javascript version of Fraction Bars is based on
// the Transparent Media desktop version of Fraction Bars,
// which in turn was based on the original TIMA Bars software
// by John Olive and Leslie Steffe.
// We thank them for allowing us to update that product.



FB.Utilities = function Utilities() {
	this.shiftKeyDown = false ;
	this.ctrlKeyDown = false ;
};

//First attempt
FB.Utilities.file_list="";
FB.Utilities.file_index=0;
//

FB.Utilities.flag=['it,sp,rpt,lng'];
FB.Utilities.flag[0]=false;
FB.Utilities.flag[1]=false;
FB.Utilities.flag[2]=false;
FB.Utilities.flag[3]=false;
FB.Utilities.USE_CURRENT_SELECTION = 'useCurrent' ;
FB.Utilities.USE_LAST_SELECTION = 'useLast' ;


// NOTE: the original Utilities.include_js dynamically injected <script> tags.
// It is intentionally removed: the sealed build inlines all code under a strict
// CSP, and runtime script injection has no place in a hermetically-sealed,
// no-network deployment.

// Coercion helpers used when importing save files so that corrupt or
// hand-edited data renders safely instead of producing invalid SVG attributes.
FB.Utilities.toFinite = function (v, def) {
  var n = Number(v);
  return isFinite(n) ? n : (def || 0);
};
FB.Utilities.toNonNeg = function (v) {
  var n = Number(v);
  return (isFinite(n) && n > 0) ? n : 0;
};

FB.Utilities.createFraction = function(numerator, denominator) {
  // Calculate the (approximate) fraction for this measurement.
  // Basic algorigm taken from Dr. Math at the Math Forum...
  // Reference: Dr. Math, "Reducing Fractions to Lowest Terms" (mathforum.org).

  var max_terms = 30 ;
  var min_divisor = 0.000001 ;
  var max_error = 0.00001 ;

  var v = numerator / denominator ;
  var f = v ;

  var n1 = 1 ;
  var d1 = 0 ;
  var n2 = 0 ;
  var d2 = 1 ;

  var a, i, n, d ;

  for (i = 0; i < max_terms; i++) {
    a = Math.round(f) ;
    f = f - a ;
    n = n1 * a + n2 ;
    d = d1 * a + d2 ;

    n2 = n1 ;
    d2 = d1 ;

    n1 = n ;
    d1 = d ;

    if (f < min_divisor && Math.abs(v-n/d) < max_error) {
      break ;
    }

    f = 1/f ;
  }

  if (Math.floor(v) == v) {
  	return v ;
  }
  else{
  	return Math.abs(n) + "/" + Math.abs(d) ;
  }
};

FB.Utilities.log = function(msg) {
	if( window.console ) {
		console.log( msg ) ;
	}
};

FB.Utilities.colorLuminance = function(hex, lum) {

  // validate hex string
  hex = String(hex).replace(/[^0-9a-f]/gi, '');
  if (hex.length < 6) {
    hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
  }
  lum = lum || 0;

  // convert to decimal and change luminosity
  var rgb = "#", c, i;
  for (i = 0; i < 3; i++) {
    c = parseInt(hex.substr(i*2,2), 16);
    c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16);
    rgb += ("00"+c).substr(c.length);
  }

  return rgb;
};

FB.Utilities.getMarkedIterateFlag = function() {
  // Vanilla DOM replacement for the original library-based selector read of
  // #marked-iterate. Returns false when the element is absent (headless tests).
  var el = (typeof document !== 'undefined' && document.getElementById)
    ? document.getElementById('marked-iterate')
    : null;
  return !!el && el.getAttribute('data-flag') === 'true';
};
