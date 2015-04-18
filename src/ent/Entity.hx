package ent;

enum State {
	Stand;
	Jump;
	Attack;
	Catch;
}

class Entity {

	var game : Game;
	var feets : Float;
	var height : Float;
	var state(default, set) : State;
	var hitBounds : h2d.col.Bounds;
	var gravity = true;
	public var acc : Float = 0.;
	public var kind : Kind;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var spr : h2d.Anim;
	public var anim(default, null) : String;

	public function new(k, x, y) {
		if( Math.isNaN(feets) ) feets = 16;
		if( Math.isNaN(height) ) height = 16;
		game = Game.inst;
		this.kind = k;
		spr = new h2d.Anim([]);
		game.level.root.add(spr, 1);
		this.x = x;
		this.y = y;
		game.entities.push(this);
		state = Stand;
		switch( k ) {
		case Rotator: gravity = false;
		default:
		}
	}

	public function remove() {
		game.entities.remove(this);
		spr.remove();
	}

	inline function get_x() {
		return spr.x / 16;
	}

	inline function get_y() {
		return spr.y / 16;
	}

	inline function set_x(v:Float) {
		spr.x = v * 16;
		return v;
	}

	inline function set_y(v:Float) {
		spr.y = v * 16;
		return v;
	}

	function getSpeed( anim : String ) {
		return 15.;
	}

	function randt() {
		return hxd.Math.random() * hxd.Timer.tmod;
	}

	function getAnim( anim : String ) : Array<h2d.Tile> {
		if( StringTools.endsWith(anim, "_rev") ) {
			var a = getAnim(anim.substr(0, -4));
			if( a == null ) return null;
			a = a.copy();
			a.reverse();
			return a;
		}
		var frames = game.frames.get(kind.toString());
		if( frames == null ) throw "No frames for " + kind;
		return frames.get(anim);
	}

	function hasAnim( anim : String ) {
		return getAnim(anim) != null;
	}

	function getBounds() {
		if( hitBounds == null ) {
			hitBounds = h2d.col.Bounds.fromValues( -feets * 0.8 / 16, -height / 16, feets / 16, height / 16);
		}
		return hitBounds;
	}

	public function checkHit( e : Entity, ?bounds : h2d.col.Bounds ) {
		if( bounds == null ) bounds = e.getBounds();
		var b = getBounds().clone();
		b.offset(x - e.x, y - e.y);
		return b.collide(bounds);
	}

	public function play( anim : String, ?onEnd : Void -> Void ) {
		if( this.anim == anim ) {
			spr.onAnimEnd = onEnd == null ? function() { } : onEnd;
			return;
		}
		var fl = getAnim(anim);
		if( fl == null  ) throw "No anim " + kind + "." + anim;
		this.anim = anim;
		spr.play(fl);
		spr.loop = true;
		spr.speed = getSpeed(anim);
		spr.onAnimEnd = onEnd == null ? function() { } : onEnd;
	}

	function collide( dx:Float, dy :Float ) {
		return game.level.collide(this, x + dx, y + dy);
	}

	public function moveX( dx : Float ) {
		move(dx, 0);
	}

	public function moveY( dy : Float ) {
		move(0, dy);
	}

	function move( dx : Float, dy : Float ) {


		x += dx;

		var way : Float = dx < 0 ? -1 : 1;

		way *= 0.5 / 16;
		if( collide(feets * way, -0.001) || collide(feets * way, -height / 16) || collide(feets * way, -height * 0.5 / 16) )
			x = (dx < 0 ? Math.floor(x) : (Math.ceil(x) - 0.001)) - feets * way;

		y += dy;
		if( dy < 0 ) {

			if( collide(-feets * 0.5 / 16,  -height / 16) || collide(0, - height / 16) || collide(feets * 0.5 / 16, - height / 16) ) {
				y = Math.ceil(y - height / 16) + height/16;
				if( acc < 0 ) acc = 0;
			}

		} else if( collide(- feets * 0.5 / 16, - 0.001) || collide(0, - 0.001) || collide(feets * 0.5 / 16, - 0.001) ) {
			if( state == Jump ) state = Stand;
			y = Math.floor(y - 0.001);
			acc = 0;
		}
	}

	function set_state(s) {
		state = s;
		switch( s ) {
		case Stand:
			play("default");
		case Jump:
			if( hasAnim("jump") ) play("jump");
		case Attack:
			play("attack", function() state = Stand);
		case Catch:
			play("catch");
		}
		return s;
	}

	public function update(dt:Float) {
		if( gravity ) {
			acc += dt * 0.02;
			if( acc > 0.9 ) acc = 0.9;
			if( acc > 0.1 && state == Stand ) state = Jump;
			moveY(acc * dt);
		}
	}

}