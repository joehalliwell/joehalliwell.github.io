addSketch("wiggle2", new function() {
	var bounds = Math.min(canvas.width, canvas.height) * 0.2;
	var ang = 0;
	var start = new Vec(canvas.width/2, canvas.height/2 + bounds);
	var pickPoint = function() {
		ang = ang + Math.PI + uniform(Math.PI/8, Math.PI/4);
		var delta = new Vec(0, bounds * uniform(0.1, 1.0)).rotate(ang);
		return new Vec(canvas.width/2, canvas.height/2).add(delta);
	};
	var end = pickPoint();
	var startTime = time;
	var period = 0.2;
	var endTime = time + period;

	this.title = "Wiggle II";
	this.info = "Trying to reproduce the after effects wiggle";
	this.clear = "rgba(128,128,128,0.1)";
	this.render = function(ctx) {
	
		// Done?
		if (time > endTime) {
			start = end;
			startTime = time;
			endTime = time + period;
			end = pickPoint();
		}
		
		var pos = interp(start, end, (time - startTime) / period, ease.out);

		ctx.fillStyle="rgba(0,0,0,1.0)";
		drawBlob(ctx, pos.x, pos.y, 100);
	};
}
);
