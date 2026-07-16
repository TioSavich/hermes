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



FB.Mat = function Mat() {
	//TODO: convert x, y to a Point?
	this.x = null ;
	this.y = null ;
	this.w = null ;
	this.h = null ;
	this.size = null ;
	this.color = null ;
//	this.splits = [] ;
//	this.label = '' ;
//	this.fraction = '' ;
	this.type = null ;
	this.isSelected = false ;
};



FB.Mat.prototype.copy = function(with_offset) {
	var offset = 10 ;
	var b = new FB.Bar() ;

	if (with_offset === false) {
		offset = 0;
	}

	b.x = this.x + offset ;
	b.y = this.y + offset ;
	b.w = this.w ;
	b.h = this.h ;
	b.size = this.size ;
	b.color = this.color ;
//	b.splits = this.copySplits() ;
//	b.label = this.label ;
//	b.isUnitBar = false ;
//	b.fraction = this.fraction ;
	b.type = this.type ;
	b.isSelected = true ;

	return b ;
};


FB.Mat.prototype.nearestEdge = function(p) {
	// return a string indicating which edge is the closest one to the given point (p)
	var closestEdge = 'bottom' ;
	var dl = p.x - this.x ;
	var dr = this.w - dl ;
	var dt = p.y - this.y ;
	var db = this.h - dt ;

	if (dl <= dr && dl <= dt && dl <= db ) {
		closestEdge = "left" ;
	} else if ( dr <= dl && dr <= dt && dr <= db ) {
		closestEdge = "right" ;
	} else if ( dt <= dl && dt <= dr && dt <= db ) {
		closestEdge = "top" ;
	}
	return closestEdge ;
};

FB.Mat.prototype.toggleSelection = function() {};

// static methods

FB.Mat.create = function(x, y, w, h, type, color) {
	var b = new FB.Mat() ;
	b.x = x ;
	b.y = y ;
	b.w = w ;
	b.h = h ;
	b.size = w * h ;
	b.color = color ;
	b.type = type ;
	return b ;
};

FB.Mat.createFromMouse = function(p1, p2, type, color) {
	var w = Math.abs(p2.x - p1.x) ;
	var h = Math.abs(p2.y - p1.y) ;
	var p = FB.Point.min( p1, p2 ) ;
	var b = FB.Mat.create(p.x, p.y, w, h, type, color) ;
	return b ;
};

FB.Mat.distanceBetween = function(b1, b2) {
	var p = new FB.Point() ;
	var totalDistance = Math.max(b1.x + b1.w, b2.x + b2.w) - Math.min(b1.x, b2.x) ;
	p.x = totalDistance - b1.w - b2.w ;
	totalDistance = Math.max(b1.y + b1.h, b2.y + b2.h) - Math.min(b1.y, b2.y) ;
	p.y = totalDistance - b1.h - b2.h ;
	return p ;
};

FB.Mat.copyFromJSON = function(JSON_Mat) {
	var b = new FB.Mat() ;


	var F = FB.Utilities;
	b.x = F.toFinite(JSON_Mat.x) ;
	b.y = F.toFinite(JSON_Mat.y) ;
	b.w = F.toNonNeg(JSON_Mat.w) ;
	b.h = F.toNonNeg(JSON_Mat.h) ;
	b.size = F.toNonNeg(JSON_Mat.size) ;
	b.color = (typeof JSON_Mat.color === 'string') ? JSON_Mat.color : '#888888' ;

	b.type = (typeof JSON_Mat.type === 'string') ? JSON_Mat.type : 'mat' ;
	b.isSelected = false ;

	return b ;
};
