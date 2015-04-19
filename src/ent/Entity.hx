package ent;

enum State {
	Stand;
	Jump;
	Attack;
	Catch;
}

class Entity {

	public static function create( k : Kind, x, y ) : Entity {
		return switch( k ) {
			case Npc:
				new Npc(k, x, y);
			case Rock:
				new Rock(k, x, y);
			case Spider:
				new Spider(k, x, y);
			default:
				new Entity(k, x, y);
		};
	}

	var game : Game;
	var feets : Float;
	var height : Float;
	var state(default, set) : State;
	var hitBounds : h2d.col.Bounds;
	var gravity = true;
	var accX = 0.;
	var canPush(default, set) = true;
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
		case Rotator:
			gravity = false;
			game.level.root.add(spr, 2);
		default:
		}
		init();
	}

	function init() {
	}

	public function hit( by : Entity ) {
		var s = hxd.Res.sfx;
		switch( kind ) {
		case Rotator:
			game.hero.catchRot(this);
		case Rock:
			var r = s.break_rock;
			if( !r.isPlaying() ) r.play();
			destroy();
		case Npc:
		case Spider:
			s.die1.play();
			destroy();
		default:
			destroy();
		}
	}

	public function destroy() {
		var t = spr.getFrame();
		var seed = Std.random(1000);
		for( px in 0...t.width>>1 )
			for( py in 0...t.height>>1 )
				if( hxd.Rand.hash(px + py * t.width, seed) % 3 == 0 )
					game.addPart(t.sub(px << 1, py << 1, 2, 2), x + ((px << 1) + t.dx) / 16, y + ((py << 1) + t.dy) / 16, hxd.Math.srand(0.1), -(0.2 + Math.random() * 0.1) * 0.8);

		remove();
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

	function set_canPush(b) {
		if( !b )
			accX = 0;
		return canPush = b;
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

	function push( dx : Float, dy : Float ) {
		if( !canPush ) return;
		accX += dx;
		acc += dy;
	}

	function move( dx : Float, dy : Float ) {

		if( Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5 ) {
			for( i in 0...2 )
				move(dx * 0.5, dy * 0.5);
			return;
		}


		x += dx;

		var way : Float = dx < 0 ? -1 : 1;

		way *= 0.5 / 16;
		if( collide(feets * way, -0.001) || collide(feets * way, -height / 16) || collide(feets * way, -height * 0.5 / 16) )
			x = (dx < 0 ? Math.floor(x) : (Math.ceil(x) - 0.001)) - feets * way;

		y += dy;
		if( dy < 0 ) {

			if( collide(-feets * 0.5 / 16,  -height / 16) || collide(0, - height / 16) || collide(feets * 0.5 / 16, - height / 16) ) {
				y = Math.ceil(y - height / 16) + height / 16;
				if( acc < 0 ) acc = 0;
			}

		} else if( collide(- feets * 0.5 / 16, - 0.001) || collide(0, - 0.001) || collide(feets * 0.5 / 16, - 0.001) ) {
			if( acc > 0 ) acc = 0;
			y = Math.floor(y - 0.001);
			if( state == Jump ) state = Stand;
		}
	}

	function set_state(s) {
		state = s;
		switch( s ) {
		case Stand:
			if( hasAnim("default") ) play("default");
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
		if( accX != 0 ) {
			var ox = x, dx = accX * 0.1 * dt;
			move(dx, 0);
			//if( Math.abs(x - (ox + dx)) > Math.abs(dx * 0.1) )
			//	accX *= -0.5;
			accX *= Math.pow(0.98, dt);
			//if( Math.abs(accX) < 0.001 ) accX = 0;
		}
	}

}