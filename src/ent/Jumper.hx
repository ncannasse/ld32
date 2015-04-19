package ent;

class Jumper extends Entity {

	var wjump = 0.;

	override function init() {
		feets = 24;
		height = 30;
		life = 5;
	}

	override function hit(by:Entity) {
		life--;
		emitParts(50);
		hxd.Res.sfx.hurt1.play();
		spr.colorAdd = new h3d.Vector(0.5, 0.5, 0.5, 0);
		if( life < 0 ) {
			hxd.Res.sfx.die2.play();
			destroy();
		}
	}

	override function update(dt:Float) {
		super.update(dt);

		if( spr.colorAdd != null ) {
			spr.colorAdd.y = spr.colorAdd.z = spr.colorAdd.x -= 0.05 * dt;
			if( spr.colorAdd.x < 0 ) spr.colorAdd = null;
		}

		switch( state ) {
		case Stand:

			if( game.hero.x < x - 1 )
				spr.scaleX = -1;
			else if( game.hero.x > x + 1 )
				spr.scaleX = 1;

			accX *= Math.pow(0.7, dt);
			wjump += dt * 1.5 / 60;
			spr.scaleY = 1 - Math.sqrt(wjump * 0.15);
			if( wjump > 1 ) {
				hxd.Res.sfx.jump2.play();
				wjump = 0;
				state = Jump;
				push(spr.scaleX, -0.35);
			}
		case Jump:
			var p = Math.pow(0.9, dt);
			spr.scaleY = spr.scaleY * p + (1 - p);
		default:
		}
		height = 25 * spr.scaleY;
		hitBounds = null;

		if( game.hero.checkHit(this) )
			game.hero.hit(this);

	}

}