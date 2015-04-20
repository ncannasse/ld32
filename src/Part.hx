
class Part extends h2d.SpriteBatch.BatchElement {
	public var vx : Float;
	public var vy : Float;
	public var time : Float;
	var game : Game;

	public function new(t) {
		super(t);
		vx = vy = 0;
		alpha = 1;
		game = Game.inst;
	}

	function randDir() {
		return Std.random(2) * 2 - 1;
	}

	override function update(dt:Float) {
		dt *= 60;
		vy += 0.01 * 16 * dt;
		vx *= Math.pow(0.99, dt);
		x += vx * dt;
		if( game.level.collide(null, x / 16, y / 16) ) {
			x -= vx * dt;
			vx *= -0.5;
		}
		y += vy * dt;
		if( game.level.collide(null, x / 16, y / 16) ) {
			y -= vy * dt;
			vy *= -0.3;
			vx *= 0.9;
		}
		if( hxd.Math.abs(vy) < 0.5 ) {
			alpha -= 0.01 * dt;
			if( alpha < 0 ) return false;
		}
		return true;
	}
}
