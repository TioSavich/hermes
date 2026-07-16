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


FB.Split = function Split(x, y, w, h, c) {
	this.x = x ;
	this.y = y ;
	this.w = w ;
	this.h = h ;
	this.color = c ;
	this.isSelected = false;
};

FB.Split.prototype.equals = function(s) {
	var _output = false ;
	if( s ) {
		_output = (s.x == this.x && s.y == this.y && s.w == this.w && s.h == this.h) ;
	}
	return _output ;
};

FB.Split.prototype.copy = function() {
	newsplit = new FB.Split(this.x, this.y, this.w, this.h, this.color);
	return newsplit;
};
