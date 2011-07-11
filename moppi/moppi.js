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
    // Special case for curvature 0
    if (this.curvature == 0) {
        ctx.moveTo(this.start.x, this.start.y);
        ctx.lineTo(this.end.x, this.end.y);
        ctx.stroke();
        return;
    }
    // General case
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
            if (this.stateTick > this.ttl / 4) this.state = Segment.GROWN;
            break;
        case Segment.GROWN:
            this.state = Segment.HOLDING;
            this.stateTick = 0;
            break;
        case Segment.HOLDING:
            if (this.stateTick > this.ttl / 2) this.state = Segment.DIED;
            break;
        case Segment.DIED:
            this.state = Segment.DYING;
            this.stateTick = 0;
        case Segment.DYING:
            if (this.stateTick > this.ttl / 4) this.state = Segment.DEAD;
            break;
        case Segment.DEAD:
            console.Log("DEAD");
            break;
    }
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
//c.translate(100,300);
//c.scale(0.5,0.5);
var t = Math.PI * 0.4;
var segments = new Array();
var s = new Segment(new Vec(0,0), 0, -t, 300, 3000, 0);
segments.push(s);

var cv = new Vec(0,0);
var tv = s.end;

function render() {
    c.fillStyle = '#eee';
    c.fillRect(0, 0, 800, 800);
    c.save();
    c.translate(400 - cv.x, 400 - cv.y);
    cv = new Vec(cv.x + (tv.x - cv.x)/100, cv.y + (tv.y - cv.y)/100);
    //console.log(cv.x + ", " + cv.y);
    //c.scale(0.5, 0.5);
    var liveSegs = new Array();
    for (i = 0; i < segments.length; i++) {
        var s = segments[i];
        s.tick();
        s.draw(c);
        if (s.state == Segment.GROWN & s.level < 5) {
            console.log("Spawning");
            if (s.level == 0) {
                liveSegs.push(new Segment(s.end, s.endAngle,
                    t * (Math.random() < 0.5 ? 1 : -1),
                    s.length - 5 + 10 * Math.random(),
                    2000,
                    0));
               tv = s.end;
            }
            else {
                liveSegs.push(new Segment(s.end, s.endAngle,
                    t * (Math.random() < 0.5 ? 1: -1),
                    s.length/ 1.1,
                    s.ttl / 1.5,
                    s.level + 1));
            }
            if (Math.random() < 0.85) {
                liveSegs.push(new Segment(s.end, s.endAngle - 0.1,
                t * 2,
                s.length / 1.5,
                s.ttl / 2,
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
