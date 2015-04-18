package ent;

class Entity {

	var game : Game;
	var feets : Float = 16;
	var height : Float = 16;
	public var acc : Float = 0.;
	public var kind : Kind;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var spr : h2d.Anim;
	public var anim(default, null) : String;

	public function new(k, x, y) {
		game = Game.inst;
		this.kind = k;
		spr = new h2d.Anim([], game.level.root);
		this.x = x;
		this.y = y;
		game.entities.push(this);
		play("default");
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

	function getAnim( anim : String ) {
		var frames = game.frames.get(kind);
		if( frames == null ) throw "No frames for " + kind;
		return frames.get(anim);
	}

	function hasAnim( anim : String ) {
		return getAnim(anim) != null;
	}

	public function play( anim : String, ?onEnd : Void -> Void ) {
		var fl = getAnim(anim);
		if( fl == null  ) throw "No anim " + kind + "." + anim;
		this.anim = anim;
		spr.play(fl);
		spr.speed = getSpeed(anim);
		spr.onAnimEnd = onEnd == null ? function() { } : onEnd;
	}

	public function moveX( dx : Float ) {
		x += dx;
		var way : Float = dx < 0 ? -1 : 1;
		way *= 0.5 / 16;
		while( game.level.collide(x + feets * way, y - 0.001) || game.level.collide(x + feets * way, y - height / 16) || game.level.collide(x + feets * way, y - height * 0.5 / 16) )
			x = (dx < 0 ? Math.floor(x) : (Math.ceil(x) - 0.001)) - feets * way;
	}

	public function moveY( dy : Float ) {
		y += dy;
		while( game.level.collide(x - feets * 0.5 / 16, y - 0.001) || game.level.collide(x + feets * 0.5 / 16, y - 0.001) ) {
			if( anim == "fall" || anim == "jump" ) play("default");
			y = Std.int(y - 0.001);
			acc = 0;
		}
	}

	public function update(dt:Float) {
		acc += dt * 0.02;
		if( acc > 0.9 ) acc = 0.9;
		if( acc > 0.1 ) {
			if( hasAnim("fall") ) {
				if( anim != "fall" ) play("fall");
			} else if( hasAnim("jump") ) {
				if( anim != "jump" ) play("jump");
			}
		}
		moveY(acc * dt);
	}

}