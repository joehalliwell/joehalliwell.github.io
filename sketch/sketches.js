var canvas = document.getElementById("canvas");
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

var ctx = canvas.getContext("2d");
var width = canvas.width;
var height = canvas.height;
var currentSketch = null;
var sketches = new Array();
var time = new Date().getTime() * 0.001; // Hmmm

function render() {
	if (currentSketch == null) return;
	if (currentSketch.clear) {
		ctx.save();
		ctx.fillStyle = currentSketch.clear;
		ctx.fillRect(0, 0, width, height);
		ctx.restore();
	}
	time = new Date().getTime() * 0.001; // Convert to seconds
	currentSketch.render(ctx);
	setTimeout(render, 10);
}

function setCurrentSketch(sketchName) {
	console.log("Setting sketch to " + sketchName);
	currentSketch = sketches[sketchName];
	$('#title').html(currentSketch.title);
	document.title = currentSketch.title;
	document.location.hash = sketchName;
}

function addSketch(sketchName, sketch) {
	sketches[sketchName] = sketch;
	if (currentSketch == null) {
		setCurrentSketch(sketchName);
		setTimeout(render, 10);
	}
}

function loadSketch(sketchName) {
	if (!sketchName) return;
	sketchName = sketchName.replace(/\//g,"").replace(/#/g,"");
	console.log("Loading " + sketchName);
	$.getScript(sketchName + ".js");
}

/* UTILITIES */

var clamp = function(val, min, max) {
    if (val < min) return min;
    if (val > max) return max;
    return val;
}

var quantize = function(val, step) {
    return (Math.floor(val / step)) * step;
}

var ease = {
	'none': function(lambda) { return lambda; },
	'in': function(lambda) { return Math.sin(lambda * Math.PI / 2); },
	'inout' : function(lambda) { return 0.5 + 0.5 * Math.sin(-Math.PI/2 + lambda * Math.PI); }
}

var interp = function(start, end, lambda, easing) {
	if (typeof(easing) == 'undefined') easing = ease.none;
	var result = new Vec(end.x, end.y);
	result.add(start, -1.0).mult(easing(lambda)).add(start);
	return result;
}

var uniform = function(start, end) {
	return Math.random() * (end - start) + start;
}

function Vec(x, y) {
    this.x = x;
    this.y = y;
}

Vec.prototype.add = function(v, alpha) {
    if (typeof(alpha) == 'undefined') alpha = 1.0;
    this.x += alpha * v.x;
    this.y += alpha * v.y;
    return this;
}

Vec.prototype.mult = function(lambda) {
	this.x *= lambda;
	this.y *= lambda;
	return this;
}

Vec.prototype.len = function() {
	return Math.sqrt(this.x * this.x + this.y * this.y);
}


Vec.prototype.rotate = function(theta) {
    nx = this.x * Math.cos(theta) - this.y * Math.sin(theta);
    ny = this.x * Math.sin(theta) + this.y * Math.cos(theta);
    this.x = nx;
    this.y = ny;
    return this;
}


function drawBlob(ctx, x, y, r) {
	ctx.beginPath();
	ctx.arc(x, y, r, 0, Math.PI*2, true);
	ctx.closePath();
	ctx.fill(); 
}

$(function() {
	sketch = location.hash;
	loadSketch(sketch);
});

