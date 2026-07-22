SCHEDULE = [0.1, 0.8, 0.1];
MAX_RECURSION = 6;
BG_COLOUR = "#f54";

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

function Segment(start, initialAngle, curvature, length, ttl, level) {
    this.start = start;
    this.initialAngle = initialAngle;
    this.length = length;
    this.curvature = quantize(curvature, Math.PI/16);
    this.ttl = ttl;
    this.level = level;
    this.endAngle = initialAngle + this.curvature;
    this.state = Segment.GROWING;
    this.stateTick = 0;
    this.computeEnd();
}

Segment.GROWING = 0;
Segment.GROWN = 1;
Segment.HOLDING = 2;
Segment.DYING = 3;
Segment.DEAD = 4;


Segment.prototype.draw = function(ctx) {
    ctx.beginPath();
    ctx.lineWidth = 1+ (1 * MAX_RECURSION) - (1 * this.level);
    // Special case for curvature 0
    if (this.curvature == 0) {
        ctx.moveTo(this.start.x, this.start.y);
        ctx.lineTo(this.end.x, this.end.y);
        ctx.stroke();
        return;
    }
    // General case
    var startAngle = 0;
    var endAngle = this.curvature;
    switch (this.state) {
        case Segment.HOLDING:
        case Segment.GROWN:
        case Segment.DIED:
            break;
        case Segment.GROWING:
            endAngle = this.stateTick * this.curvature / (this.ttl * SCHEDULE[0]);
            break;
        case Segment.DYING:
            if (this.level == 0) startAngle = this.stateTick * this.curvature / (this.ttl * SCHEDULE[2]);
            else endAngle = clamp(((this.ttl * SCHEDULE[2]) - this.stateTick) / (this.ttl * SCHEDULE[2]), 0, 1) * this.curvature;
            break;
        case Segment.DEAD:
            endAngle = 0;
    }

    if (startAngle == endAngle) return;
    var theta = this.initialAngle + ((this.curvature < 0) ? Math.PI/2 : -Math.PI/2);
    ctx.arc(this.center.x, this.center.y, this.r, theta + startAngle, theta + endAngle,
            this.curvature < 0 ? 1 : 0);
    ctx.stroke();
    return;
}

Segment.prototype.computeEnd = function() {
    if (this.curvature == 0) {
        this.end = new Vec(this.length, 0).rotate(this.initialAngle).add(this.start);
        return;
    }
    this.r = Math.abs(this.length / this.curvature);
    this.center = new Vec(0, this.curvature < 0 ? -this.r : this.r).rotate(this.initialAngle).add(this.start);
    var theta = this.curvature + ((this.curvature < 0) ? Math.PI/2 : -Math.PI/2);
    this.end = new Vec(this.r * Math.cos(theta), this.r * Math.sin(theta));
    this.end.rotate(this.initialAngle).add(this.center);
}

Segment.prototype.tick = function() {
    this.stateTick++;
    switch (this.state) {
        case Segment.GROWING:
            if (this.stateTick > (this.ttl * SCHEDULE[0])) this.state = Segment.GROWN;
            break;
        case Segment.GROWN:
            this.state = Segment.HOLDING;
            this.stateTick = 0;
            break;
        case Segment.HOLDING:
            if (this.stateTick > (this.ttl * SCHEDULE[1])) this.state = Segment.DIED;
            break;
        case Segment.DIED:
            this.state = Segment.DYING;
            this.stateTick = 0;
            break;
        case Segment.DYING:
            if (this.stateTick > (this.ttl * SCHEDULE[2])) this.state = Segment.DEAD;
            break;
        case Segment.DEAD:
            console.Log("DEAD");
            break;
    }
}

var canvas = document.getElementById('canvas');
var c = canvas.getContext('2d');
//c.translate(100,300);
//c.scale(0.5,0.5);
var t = Math.PI * 0.5;
var segments = new Array();
var s = new Segment(new Vec(0,0), 0, -t, 200, 1000, 0);
segments.push(s);

var cv = new Vec(0,0);
var tv = s.end;

function render() {
    c.fillStyle = BG_COLOUR;
    c.fillRect(0, 0, 800, 800);
    c.lineCap="round";
    c.save();
    c.translate(400 - cv.x, 400 - cv.y);
    cv = new Vec(cv.x + (tv.x - cv.x)/400, cv.y + (tv.y - cv.y)/400);
    //console.log(cv.x + ", " + cv.y);
    //c.scale(0.5, 0.5);
    var liveSegs = new Array();
    for (i = 0; i < segments.length; i++) {
        var s = segments[i];
        s.tick();
        s.draw(c);
		//tv = liveSegs[liveSegs.length - 1].end;//s.end;
        if (s.state == Segment.GROWN & s.level < MAX_RECURSION) {
            console.log("Spawning");
            if (s.level == 0) {
                liveSegs.push(new Segment(s.end,
                    s.endAngle,
                    t * (Math.random() < 0.5 ? 1 : -1),
                    100 + 50 * Math.random(),
                    s.ttl,
                    0));
                tv = liveSegs[liveSegs.length - 1].end;//s.end;
            }
            else {
                liveSegs.push(new Segment(s.end,
                    s.endAngle,
                    t * (Math.random() < 0.5 ? 1: -1),
                    s.length / 1.1,
                    s.ttl * SCHEDULE[1],
                    s.level + 1));
            }
            if (Math.random() < 0.85) {
                var dir = (Math.random() < 0.5);
                liveSegs.push(new Segment(s.end,
                    s.endAngle + (dir ? -0.1 : 0.1),
                    t * (dir ? -1 : 1),
                    s.length / 1.5,
                    s.ttl * SCHEDULE[1],
                    s.level + 1));
            }
        }
        if (s.state != Segment.DEAD) {
            liveSegs.push(s);
        }
        else {
            console.log("Killing");
        }
    }
    console.log(liveSegs.length);
    segments = liveSegs;
    c.restore();
    setTimeout(render, 5);
}

render();
