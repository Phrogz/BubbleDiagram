//*** This library is copyright 2004-2016 Gavin Kistner, !@phrogz.net
//*** It is covered under the license viewable at http://phrogz.net/SVG/libraries/_ReuseLicence.txt
//*** Reuse or modification is free provided you abide by the terms of that license.
//*** (Including the first two lines above in your source code mostly satisfies the conditions.)

/*******************************************************************************
Springz, a re-usable library to implement spring-like behaviors in JavaScript.
v1.0   20040614  Initial Release
v1.0.1 20040626  Collisions push in both directions; some speed improvements
v1.0.2 20041002  Tweaked to prevent warnings in ASV; no more    if (a=b)
v2.0   20161006  Pure JavaScript (no SVG); works with QML


Feature Overview
=================================================================================
	- The strength of each Spring may be varied.
	
	- The library performs (simple) collision prevention, if desired.
	
	- The desired length of a Spring may be non-zero, pushing/pulling objects
	  to achieve a desired separation distance.
	
	- Objects can be set to have 'mass', which effects how far each object moves
	  when the Spring pulls on it.
	  (Light objects are pushed/pulled more easily than massive ones.)
	  (Note: this does not impart inertia to the movement.)
	
	- Objects can be temporarily prevented from moving (by returning false from
	  their .moveTo() method, and/or each Spring may be temporarily inactivated.

	- The overall strength of all spring connections can be scaled.


Usage
=================================================================================

var collection = new Springz({ masses:true, scale:2.0, avoidCollisions:true, glide:0.4 });

	- masses (optional; default:false)
	  Whether or not to account for mass when moving objects.
	  If you have two objects connected by a spring, and one has a mass of 300
	  while the other has a mass of 100, the heavy object will move 1/3 the
	  distance that the light object does.

	- scale (optional; default:1)
	  A multiplier for the strength of all connections.

	- avoidCollisions (optional; default:false)
	  Whether or not to attempt to prevent objects from colliding.

	- glide (optional; default:0)
	  Inverse dampening to apply to the velocity of objects.
	  A value of 0 will prevent objects from using velocity.
	  A value of 1 will have your objects forever springing around.

var node1 = collection.node( { obj:jsObj, x:0, y:0, mass:3, radius:1 } );

	- obj (optional; default:null)
	  A JavaScript object to be associated with this node.

	- x,y (optional; default:0)
	  Initial location of the center of the node.

	- mass (optional; default:radius*radius)
	  Weight of the node; heavier nodes will move less than lighter ones.
	  Only useful if the collection has `masses:true` specified.

	- radius (optional; default:1)
	  Collision radius of the node.
	  Nodes will try not to get closer than the sum of their radii.

	- locked (optional; default:false)
	  Whether the node is allowed to move, simulating infinite mass.


collection.connect( node1, node2, { force:1.0, active:true, distance:1000 } );

	- node1, node2
	  Nodes returned from collection.node() to be connected by a spring.
	  
	- force (optional; default:1.0)
	  The numeric strength of the spring.
	  The stronger a spring, the harder it pulls on the nodes attached to it.
	  (All strengths are scaled by the collection.scale property.)
	  
	- active (optional; default:true)
	  Whether the spring between the nodes is being used.

	- distance (optional; default:0)
	  Ideal distance between the nodes (beyond the edges of their radii).
	  Use values greater than 0 to cause nodes to strive to be apart.


collection.disconnect( node1, node2 );
	
	Permanently remove a connection between two nodes.


collection.removeNode( node );

	Permanently remove a node (and any connections using it).


collection.simulate(function(nodes,springs){ ... });

	Causes all connections to be applied once.
	When complete, callback you supply will be invoked and passed two arrays,
	one of nodes, and one of springs. Iterate over these to update object
	positions and any spring representations.


collection.fitWithin(width,height);

	Move all nodes to be within [-width,width], [-height,height]


collection.uncollide();
	
	Perform a single pass through the node set and move nodes off each other
	if they overlap. (May still result in some overlap.)

	
*******************************************************************************/

.pragma library

var collectionDefaults = {
	masses:    false,
	scale:     1.0,
	uncollide: false,
	glide:     0.5,
	maxSpeed:  1e2
};

var nodeDefaults = {
	obj:    null,
	x:      0,
	y:      0,
	vx:     0,
	vy:     0,
	mass:   0,
	radius: 0,
	locked: false
};

var connectionDefaults = {
	force:    1,
	active:   true,
	distance: 0
};

function Collection(options){
	mergeDefaults(this,options,collectionDefaults);
	this.glide = Math.max(0,Math.min(1,this.glide));
	this.nodes = [];
	this.connections = [];
	this.nodeById = {};
	this.connectionById = {};
}

Collection.prototype.node = function(opts){
	var n = new Node(opts);
	n.id  = this.nodes.length;
	this.nodes.push(n);
	this.nodeById[n.id] = n;
	return n;
};

Collection.prototype.connect = function(n1,n2,opts){
	this.disconnect(n1,n2);
	var c = new Connection(n1,n2,opts);
	c.id = this.connections.length;
	this.connections.push(c);
	this.connectionById[c.id] = c;
	return c;
};

Collection.prototype.disconnect = function(n1,n2){
	for (var i=this.connections.length;i--;){
		var c = this.connections[i];
		if ((c.node1==n1 && c.node2==n2) || (c.node1==n2 && c.node2==n1)){
			delete this.connectionById[c.id];
			this.connections.splice(i,1);
			return c;
		}
	}
};

Collection.prototype.removeNode = function(n){
	delete this.nodeById[n.id];
	for (var i=this.nodes.length;i--;){
		if (this.nodes[i]==n){
			this.nodes.splice(i,1);
			break;
		}
	}
	for (var i=this.connections.length;i--;){
		var c = this.connections[i];
		if (c.node1==n || c.node2==n){
			delete this.connectionById[c.id];
			this.connections.splice(i,1);
		}
	}
};

Collection.prototype.simulate = function(callback){
	var c,n1,n2,dx,dy;
	for (var i=this.connections.length;i--;){
		c=this.connections[i];
		n1=c.node1, n2=c.node2;
		if (!c.active || (n1.locked && n2.locked)) continue;
	    dx = (n2.x-n1.x) || (Math.random()-0.5);
	    dy = (n2.y-n1.y) || (Math.random()-0.5);
	    var distance  = Math.sqrt(dx*dx + dy*dy);
	    var deviation = distance - (c.distance + n1.radius + n2.radius);

	    var force = (c.force>0 ? deviation : 1/Math.pow(distance,0.2)) * this.scale * c.force * 0.5;

		var force1, force2;
		if (this.masses){
			var mass1 = n1.locked ? (1/0) : n1.mass || (n1.radius*n1.radius);
			var mass2 = n2.locked ? (1/0) : n2.mass || (n2.radius*n2.radius);
			force2 = (1-(force1=mass1/(mass1+mass2)))*force;
			force1 *= force;
		} else force1 = force2 = force/2;

	    // FIXME: if glide is 0, only the last-evaluated connection will move objects
		n1.vx = n1.vx*this.glide + dx*force2;
		n1.vy = n1.vy*this.glide + dy*force2;
		n2.vx = n2.vx*this.glide - dx*force1;
		n2.vy = n2.vy*this.glide - dy*force1;
	}

	for (var i=this.nodes.length;i--;){
	    var n = this.nodes[i];

	    // Prevent objects moving too fast (can result in NaN)
	    if      (n.vx> this.maxSpeed) n.vx =  this.maxSpeed;
	    else if (n.vx<-this.maxSpeed) n.vx = -this.maxSpeed;
	    if      (n.vy> this.maxSpeed) n.vy =  this.maxSpeed;
	    else if (n.vy<-this.maxSpeed) n.vy = -this.maxSpeed;

	    n.x += n.vx;
	    n.y += n.vy;
	}

	if (this.preventCollisions) this.uncollide();
	if (callback) callback(this.nodes,this.connections);
};

Collection.prototype.fitWithin = function(width,height){
	this.nodes.forEach(function(n){
		if      (n.x > (width-n.radius) ) n.x = width-n.radius;
		else if (n.x < (n.radius-width) ) n.x = n.radius-width;
		if      (n.y > (height-n.radius)) n.y = height-n.radius;
		else if (n.y < (n.radius-height)) n.y = n.radius-height;
	});
};

Collection.prototype.uncollide = function(callback){

	if (callback) callback(this.nodes,this.connections);
};

function Node(options){
	mergeDefaults(this,options,nodeDefaults);
}

function Connection(n1,n2,options){
	if (!(n1 instanceof Node) || !(n2 instanceof Node)) return console.error("Connections can only be made between nodes returned from Collection.node()");
	mergeDefaults(this,options,connectionDefaults);
	this.node1 = n1;
	this.node2 = n2;
}

function mergeDefaults(o,opts,defaults){
	for (var k in defaults) o[k] = ((opts && (k in opts)) ? opts : defaults)[k];
}
