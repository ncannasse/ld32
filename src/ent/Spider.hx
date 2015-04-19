package ent;

class Spider extends Entity {

	override function init() {
		play("run");
		feets = 24;
		height = 13;
	}

	override function update( dt : Float) {
		moveX(spr.scaleX * 0.08 * dt);
		if( !collide((feets/16) * 0.5 * spr.scaleX, 0.1) || collide( ((feets/16) * 0.5 + 0.05) * spr.scaleX, -height / 32) )
			spr.scaleX *= -1;

		if( game.hero.checkHit(this) )
			game.hero.hit(this);
	}

}