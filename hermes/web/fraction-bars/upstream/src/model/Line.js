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


FB.Line = function Line(x1, y1, x2, y2) {
	this.x1 = x1 ;
	this.y1 = y1 ;
	this.x2 = x2 ;
	this.y2 = y2 ;
};

FB.Line.prototype.equals = function(line) {
	var _output ;
	if( line ) {
		_output = (this.x1 == line.x1 && this.y1 == line.y1 && this.x2 == line.x2 && this.y2 == line.y2) ;
	}
	return _output ;
}
