addSketch("wiggle3", new function() {
	var bounds = Math.min(canvas.width, canvas.height) * 0.2;
	var ang = uniform(0, Math.PI/2);
	var start = new Vec(canvas.width/2, canvas.height/2 + bounds);
	var angDrift = Math.PI/8;
	var pickPoint = function() {
		ang = ang + Math.PI + uniform(-angDrift, angDrift);
		var delta = new Vec(0, bounds).rotate(ang);
		return new Vec(canvas.width/2, canvas.height/2).add(delta);
	};
	var end = pickPoint();
	var startTime = time;
	var period = 0.3;
	var endTime = time + period;
	
	// The point we're animating
	var x = start.copy();
	var v = new Vec(0,0);

	this.title = "Wiggle III";
	this.info = "Trying to reproduce the after effects wiggle";
	this.clear = "rgba(128,128,128,1)";
	this.render = function(ctx) {
	
		// Done?
		if (time > endTime) {
			start = end;
			startTime = time;
			endTime = time + period;
			end = pickPoint();
		}
		
		var pos = interp(start, end, (time - startTime) / period);
		
		// Spring force -- fiddle factors ahoy!
		var f = pos.copy().add(x, -1);
		f.add(v, new Vec(v.x * v.x, x.y * v.y).len() * -0.000002); // Drag
		v.add(f.mult(timeDelta * 100)); // Mass and spring constant
		x.add(v, timeDelta);
		
		ctx.fillStyle="rgba(0,0,0,1.0)";
		drawBlob(ctx, x.x, x.y, 100);	
		ctx.fillStyle="rgba(255,0,0,1.0)";
		drawBlob(ctx, pos.x, pos.y, 10);
		
	};
}
);
