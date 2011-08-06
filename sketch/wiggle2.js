addSketch("wiggle2", new function() {
	var bounds = Math.min(canvas.width, canvas.height) * 0.2;
	var ang = 0;
	var start = new Vec(canvas.width/2, canvas.height/2 + bounds);
	var pickPoint = function() {
		ang = ang + Math.PI + uniform(Math.PI/8, Math.PI/4);
		var delta = new Vec(0, bounds).rotate(ang);
		return new Vec(canvas.width/2, canvas.height/2).add(delta);
		//if ((start.x + delta.x) > (canvas.width/2 + bounds) || (start.x + delta.x) < (canvas.width/2 - bounds)) delta.x = -delta.x;
		//if ((start.y + delta.y) > (canvas.height/2 + bounds) || (start.y + delta.y) < (canvas.height/2 - bounds)) delta.y = -delta.y;
		//return delta.add(start, 1.0);
	}
	var end = pickPoint();
	var startTime = time;
	var period = 1.0;
	var endTime = time + period;

	this.title = "Wiggle II";
	this.info = "Trying to reproduce the after effects wiggle";
	this.clear = "rgba(128,128,128,1.0)";
	this.render = function(ctx) {
	
		// Done?
		if (time > endTime) {
			start = end;
			startTime = time;
			endTime = time + period;
			end = pickPoint();
		}
		
		var pos = interp(start, end, (time - startTime) / period, ease.inout);

		ctx.fillStyle="rgba(0,0,0,1.0)";
		drawBlob(ctx, pos.x, pos.y, 100);
	}
}
);
