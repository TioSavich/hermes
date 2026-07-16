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


// Module flag replacing the original global coupling on
// fbCanvasObj.currentAction == "repeat". Controller (Task 10) sets this.
FB.repeatModeActive = false;

// The original model called the browser global alert() directly inside
// join()/repeat(). Outside a browser (Node tests) that global is absent and
// would throw a ReferenceError on the no-match path. Resolve once to a safe
// local that prefers the real browser alert (verbatim behavior) and is a
// no-op otherwise. No logic change.
function alert(msg) {
	// Prefer the app's accessible, non-blocking toast when wired; otherwise fall
	// back to the browser alert; in headless tests this is a no-op.
	if (FB && typeof FB.notify === 'function') {
		FB.notify(msg);
	} else if (typeof window !== 'undefined' && typeof window.alert === 'function') {
		window.alert(msg);
	}
}

FB.Bar = function Bar() {
	//TODO: convert x, y to a Point?
	this.x = null ;
	this.y = null ;
	this.w = null ;
	this.h = null ;
	this.size = null ;
	this.color = null ;
	this.splits = [] ;
	this.label = '' ;
	this.isUnitBar = false ;
	this.fraction = '' ;
	this.type = null ;
	this.isSelected = false ;
	this.repeatUnit = null;    // This is a copy of whatever the bar looks like at the moment "repeat" mode is turned on.
	this.selectedSplit = null;
};

FB.Bar.prototype.measure = function(targetBar) {
	this.fraction = FB.Utilities.createFraction( this.size, targetBar.size ) ;
};
FB.Bar.prototype.clearMeasurement = function() {
	this.fraction = '' ;
};
FB.Bar.prototype.drawMeasurement = function() {};


FB.Bar.prototype.addSplit = function(x, y, w, h, c) {
	this.addSplitToList(this.splits, x, y, w, h, c);
};

FB.Bar.prototype.addSplitToList = function(list, x, y, w, h, c) {
	var split = new FB.Split(x, y, w, h, c) ;
	if( this.splits.length > 0 ) {
		for( i = 0; i < this.splits.length; i++ ) {
			if( split.equals( this.splits[i] )) {
				return ;
			}
		}
	}
	list.push( split ) ;
};

FB.Bar.prototype.clearSplits = function() {
	this.splits = [] ;
};

FB.Bar.prototype.copySplits = function() {
	var splitsCopy = [] ;

	for( var i = 0; i < this.splits.length; i++ ) {
		splitsCopy.push( this.splits[i].copy() ) ;
	}

	return splitsCopy ;
};

FB.Bar.prototype.hasSelectedSplit = function() {
	for (var i = 0; i < this.splits.length; i++) {
		if (this.splits[i].isSelected) {
			return true;
		}
	}
	return false;
};

FB.Bar.prototype.updateColorOfSelectedSplit = function(in_color) {
		for (var i = 0; i < this.splits.length; i++) {
		if (this.splits[i].isSelected) {
			this.splits[i].color = in_color;
		}
	}
	return false;
};

FB.Bar.prototype.clearSplitSelection = function() {
	this.selectedSplit = null;
	for (var i = 0; i < this.splits.length; i++) {
		this.splits[i].isSelected = false;
	}
};


FB.Bar.prototype.updateSplitSelectionFromState = function() {
	this.selectedSplit = null;
	for( var i = 0; i < this.splits.length; i++ ) {
		if( this.splits[i].isSelected ) {
			this.selectedSplit = this.splits[i];
		}
	}
};


FB.Bar.prototype.selectSplit = function(mouse_loc) {

	this.selectedSplit = this.splitClickedOn(mouse_loc);
};

FB.Bar.prototype.findSplitForPoint = function(p)  {
	for( var i = this.splits.length-1; i >= 0; i-- ) {
		if( p.x > this.splits[i].x+this.x &&
			p.x < this.splits[i].x+this.x + this.splits[i].w &&
			p.y > this.splits[i].y+this.y &&
			p.y < this.splits[i].y+this.y + this.splits[i].h) {

			return(this.splits[i]);
		}
	}
	return null;
};

FB.Bar.prototype.splitClickedOn = function(mouse_loc) {
	for( var i = this.splits.length-1; i >= 0; i-- ) {
		// FB.Utilities.log(i);
		if( mouse_loc.x > this.x + this.splits[i].x &&
			mouse_loc.x < this.x + this.splits[i].x + this.splits[i].w &&
			mouse_loc.y > this.y + this.splits[i].y &&
			mouse_loc.y < this.y + this.splits[i].y + this.splits[i].h)
		{
			this.clearSplitSelection();
			this.splits[i].isSelected = true ;
			return this.splits[i] ;
		}
	}
	return null ;
};

FB.Bar.prototype.removeASplit = function(split) {
	// If this bar has this split, remove it.
	var newsplits = [];
	for (var i = this.splits.length - 1; i >= 0; i--) {
		if (this.splits[i] !== split) {
			newsplits.push(this.splits[i]);
		}
	}
	this.splits = newsplits;
};



//////////////////////////
FB.Bar.prototype.splitBarAtPoint = function(split_point, vert_split) {
	var the_split = this.findSplitForPoint(split_point);

	if ((the_split !== null)) {

		// Splitting a single split
		if (!vert_split) {
			this.addSplit(the_split.x, the_split.y, split_point.x-(this.x+the_split.x), the_split.h, the_split.color);
			this.addSplit(split_point.x-this.x, the_split.y, the_split.w-(split_point.x-(this.x+the_split.x)), the_split.h, the_split.color);
		} else {
			this.addSplit(the_split.x, the_split.y, the_split.w, split_point.y-(this.y+the_split.y), the_split.color);
			this.addSplit(the_split.x, split_point.y-this.y, the_split.w, the_split.h-(split_point.y-(this.y+the_split.y)), the_split.color);
		}
		this.removeASplit(the_split);
	} else {
		// Adding a split to a bar with none
		if (this.splits.length == 0) {
			// Make sure we really have no splits before doing this.
			if (!vert_split) {
				this.addSplit(0, 0, split_point.x-this.x, this.h, this.color);
				this.addSplit(split_point.x-this.x, 0, this.x+this.w-split_point.x, this.h, this.color);
			} else {
				this.addSplit(0, 0, this.w, split_point.y-this.y, this.color);
				this.addSplit(0, split_point.y-this.y, this.w, this.y+this.h-split_point.y, this.color);
			}
		}
	}

};

FB.Bar.prototype.initialSplits = function(num_splits, vert_direction) {
// Used for when there are no existing splits in a bar
	var split_interval = 0;
	var x = 0;
	var y = 0;
	var i = 0;

	if (vert_direction === true) {
		split_interval = this.w / num_splits;
		for ( i = 0; i < num_splits; i++) {
			x = i*split_interval;
			this.addSplit(x, y, split_interval, this.h, this.color);
		}
	} else {
		split_interval = this.h / num_splits;
		for ( i = 0; i < num_splits; i++) {
			y = i*split_interval;
			this.addSplit(x, y, this.w, split_interval, this.color);
		}
	}
};

FB.Bar.prototype.splitSelectedSplit = function(num_splits, vert_direction) {

	this.updateSplitSelectionFromState();
	if (this.selectedSplit === null) {return;}

	var split_interval = 0;
	var x = this.selectedSplit.x;
	var y = this.selectedSplit.y;
	var i = 0;

	if (vert_direction === true) {
		split_interval = this.selectedSplit.w / num_splits;
		for ( i = 0; i < num_splits; i++) {
			x = i*split_interval + this.selectedSplit.x;
			this.addSplit(x, y, split_interval, this.selectedSplit.h, this.selectedSplit.color);
		}
	} else {
		split_interval = this.selectedSplit.h / num_splits;
		for ( i = 0; i < num_splits; i++) {
			y = i*split_interval +this.selectedSplit.y;
			this.addSplit(x, y, this.selectedSplit.w, split_interval, this.selectedSplit.color);
		}
	}
	var place = 0;
	while (this.splits[place] !== this.selectedSplit) {
		place++;
	}
	this.splits.splice(place, 1);
};



FB.Bar.prototype.wholeBarSubSplit = function(a_split, vert_direction, subsplit_interval) {
	// Takes a single split and tries to subsplit it based on a whole bar fraction
	// If there is no subsplit, we just return a list containing the original split.
	// Otherwise we return the subsplits, but not the original split
	var new_subsplit_list = [];
	var i = 0;
	var split_hit = false; // Start out assuming we have not hit a split
	var lower_bound = 0; //storing the lower boundary of a new split
	var upper_bound = 0; // self explanatory
	var corrected_interval = 0; // storing the corrected width or height of a new split (in case it is cut off)

	if (vert_direction === true) {
		for (i = subsplit_interval; Math.floor(i)<= this.w; i = i + subsplit_interval) {
			if (	((i > a_split.x)						&& (i < a_split.x + a_split.w)) ||
					((i - subsplit_interval > a_split.x )	&& (i - subsplit_interval < a_split.x + a_split.w)) ) {
				split_hit = true;
				lower_bound =  (a_split.x > (i - subsplit_interval)) ? a_split.x : (i - subsplit_interval);
				upper_bound =  ((a_split.x + a_split.w) < i) ? a_split.x + a_split.w : i;
				corrected_interval = upper_bound - lower_bound;
				this.addSplitToList(new_subsplit_list, lower_bound, a_split.y, corrected_interval, a_split.h, a_split.color);
			}
		}
	} else {
		for (i = subsplit_interval; Math.floor(i)<= this.h; i = i + subsplit_interval) {
			if (	((i > a_split.y)						&& (i < a_split.y + a_split.h)) ||
					((i - subsplit_interval > a_split.y )	&& (i - subsplit_interval < a_split.y + a_split.h)) ) {
				split_hit = true;
				lower_bound =  (a_split.y > (i - subsplit_interval)) ? a_split.y : (i - subsplit_interval);
				upper_bound =  ((a_split.y + a_split.h) < i) ? a_split.y + a_split.h : i;
				corrected_interval = upper_bound - lower_bound;
				this.addSplitToList(new_subsplit_list, a_split.x, lower_bound, a_split.w, corrected_interval, a_split.color);
			}
		}
	}
	if (split_hit === false) {
		new_subsplit_list.push(a_split);
	}
	return new_subsplit_list;
};



FB.Bar.prototype.wholeBarSplits = function(num_splits, vert_direction) {
	// Tries to split a whole bar, despite subsplits.
	var new_splits_list = [];
	var split_interval = 0;
	var list_passback = [];

	if (this.splits.length === 0) {
		// Doing initial splits because there are no existing splits
		this.initialSplits(num_splits, vert_direction);
	} else {
		// Doing subsequent splits because we already have some splits
		if (vert_direction === true) {
			split_interval = this.w / num_splits;
		} else {
			split_interval = this.h / num_splits;
		}
		// For every split
		for (var i = this.splits.length - 1; i >= 0; i--) {
			// Attempt to subsplit it and concat the result into the new list
			list_passback = this.wholeBarSubSplit(this.splits[i], vert_direction, split_interval);
			new_splits_list = new_splits_list.concat(list_passback);
		}
		// When complete, use the new list to replace the old list.
		this.clearSplits();
		this.splits = new_splits_list;
	}
};



FB.Bar.prototype.breakApart = function() {
	var newBars = [] ;
	var aBar ;
	if( this.splits.length === 0 ) {
		aBar = this.copy(false) ;
		aBar.isSelected = false ;
		newBars.push( aBar ) ;
	} else {
		for( var i = 0; i < this.splits.length; i++ ) {
			newBars.push( FB.Bar.create( this.x + this.splits[i].x, this.y + this.splits[i].y, this.splits[i].w, this.splits[i].h, 'bar', this.splits[i].color )) ;
		}
	}
	return newBars ;
};

FB.Bar.prototype.copy = function(with_offset) {
	var offset = 10 ;
	var b = new FB.Bar() ;

	if (with_offset === false) {
		offset = 0;
	}
	if (FB.repeatModeActive) {
		offset=0;
	}
	b.x = this.x + offset ;
	b.y = this.y + offset ;
	b.w = this.w ;
	b.h = this.h ;
	b.size = this.size ;
	b.color = this.color ;
	b.splits = this.copySplits() ;
	b.label = this.label ;
	b.isUnitBar = false ;
	if (this.isUnitBar === true) {
		b.fraction = "" ;
	} else {
		b.fraction = this.fraction ;
	}
	b.type = this.type ;
	b.isSelected = true ;
	b.repeatUnit = this.repeatUnit;

	return b ;
};


FB.Bar.prototype.makeCopy = function() {

	// This version of the copy routine does not set isSelected to true.
	// I a using this to make a copy that is just stored, so there is no reason for
	// the bar to think it is selected.

	var offset = 10 ;
	var b = new FB.Bar() ;

	b.x = this.x + offset ;
	b.y = this.y + offset ;
	b.w = this.w ;
	b.h = this.h ;
	b.size = this.size ;
	b.color = this.color ;
	b.splits = this.copySplits() ;
	b.label = this.label ;
	b.isUnitBar = false ;
	b.fraction = this.fraction ;
	b.type = this.type ;
	b.isSelected = false ;

	return b ;
};

FB.Bar.prototype.makeNewCopy = function(with_height) {

	// This version of the copy routine does not set isSelected to true.
	// I a using this to make a copy that is just stored, so there is no reason for
	// the bar to think it is selected.

	var offset = 10 ;

	var b = new FB.Bar() ;

	b.x = this.x ;
	b.y = this.y +this.h + offset ;
	b.w = this.w * with_height;
	b.h = this.h  ;
	b.size = this.size * with_height;
	b.color = this.color ;
	b.isUnitBar = false ;
	b.type = this.type ;
	b.isSelected = false ;
	this.isSelected = false ;
	return b ;
};

FB.Bar.prototype.repeat = function(clickLoc) {

//	alert(clickLoc.x +", "+clickLoc.y);

	var govert = false;
/*	local_x = clickLoc.x - this.x;
	local_y = clickLoc.y - this.y;
	diag_slope = this.h / this.w;
	// modified by hsandir
	if (local_y > (local_x * diag_slope)) {
		govert = true;
	}*/

	if (this.repeatUnit !== null) {
		if (govert) {
			this.repeatUnit.x -= 5;
		} else {
			this.repeatUnit.y -= 5;
		}
		this.join(this.repeatUnit);
		if ((this.splits.length === 2) && (this.repeatUnit.splits.length === 0) && FB.Utilities.getMarkedIterateFlag()) {
			this.splits[1].color = this.splits[0].color;
/////////////////////////////
//			this.splits[1].color = FB.Utilities.colorLuminance(this.splits[0].color.toString(), -0.1);
		}
	} else {
		alert("Tried to Repeat when no repeatUnit was set.");
	}

};


FB.Bar.prototype.iterate = function(iterate_num, vert) {

	offset = 3;
	i_iter = 0;

	iterate_unit = this.makeCopy();
	if (vert === true) {
		iterate_unit.y += offset;
	} else {
		iterate_unit.x += offset;
	}

	start_split_num = this.splits.length;

	for (i_iter = 1; i_iter < iterate_num; i_iter++) {
		this.join(iterate_unit);
	}

	if((start_split_num === 0) && (this.splits.length >0) && FB.Utilities.getMarkedIterateFlag()) {
		//this.splits[0].color = FB.Utilities.colorLuminance(this.splits[0].color.toString(), -0.1);
	}
};

FB.Bar.prototype.join = function(b) {
	var gap = FB.Bar.distanceBetween(this,b);
	gap.x = Math.abs(gap.x);
	gap.y = Math.abs(gap.y);
	var b1, b2 ;
	var originalBar = this.copy(true) ;
	var joinDimension ='' ;

	// TODO: add check for matching dimensions

	var vertmatch = this.h == b.h;
	var horizmatch = this.w == b.w;

	if (!vertmatch && !horizmatch) {
		alert("To Join, bars must have a matching dimension in height or width.");
		return(false);
	}


//	this.x = Math.min(this.x, b.x) ;
//	this.y = Math.min(this.y, b.y) ;

	if (vertmatch && horizmatch) { // since both match, determine join dimension
//		alert("Both match!");

		if( Math.abs(gap.x) < Math.abs(gap.y) ) {
			this.h = this.h + b.h ;
			joinDimension = 'w' ;
		} else {
			this.w = this.w + b.w ;
			joinDimension = 'h' ;
		}
	} else { // just one matched
		if (vertmatch) {
//			alert("Only h matched!");
			this.w = this.w + b.w ;
			joinDimension = 'h';
		} else {
//			alert("Only w matched!");
			this.h = this.h + b.h ;
			joinDimension = 'w';
		}
	}

	this.size = this.w * this.h ;

	var i = 0;

	this.clearSplits();

	// handling will be different for vertical/horizontal joins
	if( joinDimension == 'w' ) {
//		alert("Joining along width");
		if( originalBar.y < b.y ) {
			b1 = originalBar ;
			b2 = b ;
		} else {
			b1 = b ;
			b2 = originalBar ;
		}

		this.x = b1.x;
		this.y = b1.y;

		if (b1.splits.length === 0) {
			this.addSplit(0, 0, b1.w, b1.h, b1.color) ;
		}
		if (b2.splits.length === 0) {
			this.addSplit(0, b1.h, b2.w, b2.h, b2.color ) ;
		}

		if( b1.splits.length > 0 ) {
			for(i = 0; i < b1.splits.length; i++ ) {
				this.addSplit(b1.splits[i].x, b1.splits[i].y, b1.splits[i].w, b1.splits[i].h, b1.splits[i].color ) ;
			}
		}
		if( b2.splits.length > 0 ) {
			for(i = 0; i < b2.splits.length; i++ ) {
				this.addSplit(b2.splits[i].x, b2.splits[i].y + b1.h, b2.splits[i].w, b2.splits[i].h, b2.splits[i].color ) ;
			}
		}


	} else {
//		alert("Joining along height");
		if( originalBar.x < b.x ) {
			b1 = originalBar ;
			b2 = b ;
		} else {
			b1 = b ;
			b2 = originalBar ;
		}

		this.x = b1.x;
		this.y = b1.y;

		if (b1.splits.length === 0) {
			this.addSplit(0, 0, b1.w, b1.h, b1.color) ;
		}
//		this.addSplit(0, b1.h, originalBar.w, originalBar.h, b2.c) ;
//		this.addSplit(0, b1.h, b2.w, b2.h, b2.c) ;
		if (b2.splits.length === 0) {
			this.addSplit(b1.w, 0, b2.w, b2.h, b2.color) ;
		}

		if( b1.splits.length > 0 ) {
			for(i = 0; i < b1.splits.length; i++ ) {
				this.addSplit(b1.splits[i].x, b1.splits[i].y, b1.splits[i].w, b1.splits[i].h, b1.splits[i].color ) ;
			}
		}
		if( b2.splits.length > 0 ) {
			for(i = 0; i < b2.splits.length; i++ ) {
				this.addSplit(b2.splits[i].x + b1.w, b2.splits[i].y, b2.splits[i].w, b2.splits[i].h, b2.splits[i].color ) ;
			}
		}

	}

	// this.purgeOverlappingSplits() ;


	this.clearMeasurement() ;

	return(true);
};

FB.Bar.prototype.nearestEdge = function(p) {
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

FB.Bar.prototype.toggleSelection = function() {};

FB.Bar.prototype.setRepeatUnit = function() {
	this.repeatUnit = this.makeCopy(true);
	this.repeatUnit.unPastel();
};

FB.Bar.prototype.unPastel = function() {

}

// static methods

FB.Bar.create = function(x, y, w, h, type, color) {
	var b = new FB.Bar() ;
	b.x = x ;
	b.y = y ;
	b.w = w ;
	b.h = h ;
	b.size = w * h ;
	b.color = color ;
	b.type = type ;
	return b ;
};

FB.Bar.createFromMouse = function(p1, p2, type, color) {
	var w = Math.abs(p2.x - p1.x) ;
	var h = Math.abs(p2.y - p1.y) ;
	var p = FB.Point.min( p1, p2 ) ;
	var b = FB.Bar.create(p.x, p.y, w, h, type, color) ;
	return b ;
};


FB.Bar.createFromSplit = function(s, inx, iny) {
	var b = FB.Bar.create(inx+s.x+10, iny+s.y+10, s.w, s.h, this.type, s.color) ;
	return b ;
};

FB.Bar.distanceBetween = function(b1, b2) {
	// Returns the distance vertically and horizontally between the centers
	// of two bars.
	// Given as separate dimensions in a Point object, think of the return value as the amount needed
	// to translate b1 so that the center would be precisely over b2.
	var p = new FB.Point() ;
//	var totalDistance = Math.max(b1.x + b1.w, b2.x + b2.w) - Math.min(b1.x, b2.x) ;
//	p.x = totalDistance - b1.w - b2.w ;
//	totalDistance = Math.max(b1.y + b1.h, b2.y + b2.h) - Math.min(b1.y, b2.y) ;
//	p.y = totalDistance - b1.h - b2.h ;
	p.x = b2.x - b1.x;
	p.y = b2.y - b1.y;
	return p ;
};


FB.Bar.copyFromJSON = function(JSON_Bar) {
	var b = new FB.Bar() ;


	// Coerce on import so a corrupt or hand-edited file cannot inject NaN /
	// undefined / non-string values that would produce invalid SVG attributes.
	var F = FB.Utilities;
	b.x = F.toFinite(JSON_Bar.x) ;
	b.y = F.toFinite(JSON_Bar.y) ;
	b.w = F.toNonNeg(JSON_Bar.w) ;
	b.h = F.toNonNeg(JSON_Bar.h) ;
	b.size = F.toNonNeg(JSON_Bar.size) ;
	b.color = (typeof JSON_Bar.color === 'string') ? JSON_Bar.color : '#FFFF66' ;
	b.makeSplitsFromJSON(Array.isArray(JSON_Bar.splits) ? JSON_Bar.splits : []) ;
	b.label = (JSON_Bar.label == null) ? '' : String(JSON_Bar.label) ;
	b.isUnitBar = !!JSON_Bar.isUnitBar ;
	b.fraction = (typeof JSON_Bar.fraction === 'number' || typeof JSON_Bar.fraction === 'string') ? JSON_Bar.fraction : '' ;
	b.type = (typeof JSON_Bar.type === 'string') ? JSON_Bar.type : 'bar' ;
	b.isSelected = false ;

	return b ;
};

FB.Bar.prototype.makeSplitsFromJSON = function(JSON_splits) {

	this.clearSplits();
	var F = FB.Utilities;
	for (var i = 0; i < JSON_splits.length; i++) {
		var s = JSON_splits[i] || {};
		this.addSplit(F.toFinite(s.x), F.toFinite(s.y), F.toNonNeg(s.w), F.toNonNeg(s.h),
			(typeof s.color === 'string') ? s.color : '#FFFF66');
	}
};
