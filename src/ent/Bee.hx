package ent;

class Bee extends Entity {

	var time = 0.;
	var baseY : Float;

	override function init() {
		feets = 17;
		height = 11;
		gravity = false;
		baseY = y - 0.25;
		play("run");
	}

	override function update( dt : Float) {

		time += dt;
		y = baseY + Math.sin(time * 0.1) * 0.3;
		moveX(spr.scaleX * 0.08 * dt);
		if( collide( ((feets/16) * 0.5 + 0.05) * spr.scaleX, -height / 32) )
			spr.scaleX *= -1;

		if( game.hero.checkHit(this) )
			game.hero.hit(this);
	}

}