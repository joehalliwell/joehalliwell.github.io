var clamp = function(val, min, max) {
    if (val < min) return min;
    if (val > max) return max;
    return val;
}

var quantize = function(val, step) {
    return (Math.floor(val / step)) * step;
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

Vec.prototype.rotate = function(theta) {
    nx = this.x * Math.cos(theta) - this.y * Math.sin(theta);
    ny = this.x * Math.sin(theta) + this.y * Math.cos(theta);
    this.x = nx;
    this.y = ny;
    return this;
}

function Segment(start, initialAngle, curvature, length, ttl) {
    this.start = start;
    this.initialAngle = initialAngle;
    this.length = length;
    this.curvature = quantize(curvature, Math.PI/16);
    this.ttl = ttl;
    this.endAngle = initialAngle + this.curvature;
    this.state = Segment.GROWING;
    if (this.curvature != 0) {
        this.r = Math.abs(this.length / this.curvature);
        this.center = new Vec(0, this.curvature < 0 ? -this.r : this.r).rotate(initialAngle).add(start);
    }
    this.computeEnd();
}

Segment.prototype.GROWING = 0;
Segment.prototype.GROWN = 1;
Segment.prototype.HOLDING = 2;
Segment.prototype.DYING = 3;
Segment.prototype.DEAD = 4;

Segment.prototype.draw = function(ctx) {
    ctx.beginPath();
    if (this.curvature == 0) {
        ctx.moveTo(this.start.x, this.start.y);
        ctx.lineTo(this.end.x, this.end.y);
        ctx.stroke();
        return;
    }
    var theta = this.initialAngle + ((this.curvature < 0) ? Math.PI/2 : -Math.PI/2);
    ctx.arc(this.center.x, this.center.y, this.r, theta, theta + this.curvature,
            this.curvature < 0 ? 1 : 0);
    ctx.stroke();
    return;
}

Segment.prototype.computeEnd = function() {
    if (this.curvature == 0) {
        this.end = new Vec(this.length, 0).rotate(this.initialAngle).add(this.start);
        return;
    }
    var theta = this.curvature + ((this.curvature < 0) ? Math.PI/2 : -Math.PI/2);
    this.end = new Vec(this.r * Math.cos(theta), this.r * Math.sin(theta));
    this.end.rotate(this.initialAngle).add(this.center);
}
/*
var pickCurvature = function(curv) {
    var delta = Math.PI/48;
    if (Math.random() < 0.9) return curv;
    var result = curv + (Math.random() < 0.5 ? delta : -delta);
    return clamp(result, 0.2 * -Math.PI, 0.2 *  Math.PI);
}
*/

var canvas = document.getElementById('canvas');
var c = canvas.getContext('2d');
c.translate(100,800);
c.lineWidth = 5;
var tick = 0;
var t = Math.PI * 0.85;
var s = new Segment(new Vec(0,0), 0, -t, 300, 1000);
s.draw(c);
console.log(s);
s = new Segment(s.end, s.endAngle, t, 300, 1000);
console.log(s);
//c.strokeStyle = '#f55';
s.draw(c);
//c.strokeStyle = '#5f5';
s = new Segment(s.end, s.endAngle, -t * 2, 300, 1000);
console.log(s);
s.draw(c);
//c.strokeStyle = '#000';
u = new Segment(s.end, s.endAngle, -t * 2, 100, 1000);
u.draw(c);
u = new Segment(s.end, s.endAngle, t * 2, 100, 1000);
u.draw(c);
u = new Segment(s.end, s.endAngle, -t / 2, 300, 1000);
u.draw(c);
u = new Segment(u.end, u.endAngle, -t , 300, 1000);
u.draw(c);
u = new Segment(u.end, u.endAngle, -t , 300, 1000);
u.draw(c);
u = new Segment(u.end, u.endAngle, -t/3 , 300, 1000);
u.draw(c);
u = new Segment(u.end, u.endAngle, t , 300, 1000);
u.draw(c);
