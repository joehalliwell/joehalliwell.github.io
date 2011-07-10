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
    nx = this.x * cos(theta) - this.y * sin(theta);
    ny = this.x * sin(theta) + this.y * cos(theta);
    this.x = nx;
    this.y = ny;
    return this;
}

function Segment(start, initialAngle, curvature, length, ttl) {
    this.start = start;
    this.length = length;
    this.curvature = curvature;
    this.ttl = ttl;
    this.r = this.length / this.curvature;
    this.center = new Vec(0, this.r).rotate(initialAngle).add(start);
    //this.end = 
    this.endAngle = initialAngle + curvature;
}

Segment.prototype.draw = function(ctx) {
    ctx.beginPath();
    ctx.moveTo(this.start.x, this.start.y);
    if (this.curvature < 0.01 && this.curvature > -0.01) {
        ctx.lineTo(this.end.x, this.end.y);
        ctx.stroke();
        return;
    }
    if (this.curvature > 0) {
        ctx.arc(this.center.x, this.center.y, this.r, -Math.PI/2, -Math.PI/2 + this.curvature, 0);
    }
    else {
        ctx.arc(this.center.x, this.center.y, -this.r, Math.PI/2, Math.PI/2 + this.curvature, 1);
    }
    ctx.stroke();
}

Segment.prototype.tick = function() {
    this.curvature = this.curvature/1.001;
    if (this.curvature < 0.01 && this.curvature > -0.01) this.ccode = 0;
    else {
        if (this.curvature > 0) this.ccode = 1;
        else this.ccode = 2;
        this.r = this.length / this.curvature;
    }
    switch (this.ccode) {
        case 0:
            this.end = { x: this.length, y: 0 };
            break;
        case 1:
             this.end = {
                x: Math.abs(this.r) * Math.cos(-Math.PI/2 + this.curvature),
                y: this.r + Math.abs(this.r) * Math.sin(-Math.PI/2 + this.curvature)};
            break;
        case 2:
             this.end = {
                x: Math.abs(this.r) * Math.cos(Math.PI/2 + this.curvature),
                y: this.r + Math.abs(this.r) * Math.sin(Math.PI/2 + this.curvature)};
            break;
    }
}

var clamp = function(val, min, max) {
    if (val < min) return min;
    if (val > max) return max;
    return val;
}

var quantize = function(val, step) {
    return (floor(val / step)) * step;
}

var rotate = function(v, theta) {
    return new Vec(v.x * cos(theta) - v.y * sin(theta), v.x * sin(theta) + v.y * cos(theta));
}

var pickCurvature = function(curv) {
    var delta = Math.PI/48;
    if (Math.random() < 0.9) return curv;
    var result = curv + (Math.random() < 0.5 ? delta : -delta);
    return clamp(result, 0.2 * -Math.PI, 0.2 *  Math.PI);
}

var canvas = document.getElementById('canvas');
var c = canvas.getContext('2d');
var tick = 0;
var segments = new Array();
s = new Segment(0, 100);
for (i = 0; i < 300; i++) {
    s = new Segment(0,0,pickCurvature(s.curvature),30 + Math.random() * 30);
    segments.push(s);
}
c.translate(canvas.width/2, canvas.height/2);
c.rotate(-Math.PI / 2);
c.scale(0.1,0.1);
function render() {
    var s = new Segment(0, 100);
    tick++;
    //console.log(tick);
    c.rotate(0.001);
    c.save();
    //c.fillStyle = 'rgba(255,255,255,0.008)';
    //c.fillRect(0, 0, canvas.width * 10,canvas.height * 10);
    for (i = 0; i < segments.length; i++) {
        var s = segments[i];
        s.tick();
        c.lineWidth = 10;
        c.strokeStyle = 'rgba(0,0,0,0.1)';
        s.draw(c);
        if (true) {
            c.beginPath();
            c.fillStyle = 'rgba(255,255,255,0.2)';
            c.strokeStyle = 'rgba(70,50,25,0.1)';
            c.lineWidth = 8;
            c.arc(0,0, 10, 0, Math.PI * 2, 0);
            c.fill();
            c.stroke();
        }
        //c.translate(s.end.x, s.end.y);
        //c.rotate(s.curvature);
    }
    c.restore();
    setTimeout(render, 5);
    }

render();
