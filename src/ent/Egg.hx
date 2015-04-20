package ent;

class Egg extends Entity {

	var get = false;

	override function init() {
		feets = 15;
		height = 20;
	}

	override function hit(_) {
	}

	override function update(dt:Float) {
		super.update(dt);
		if( acc == 0 && randt() < 0.02 )
			acc = -0.1;
		if( game.hero.checkHit(this) ) {
			acc = -0.03 - 0.02 * dt;
			if( !collide(0, 0.7) && !get ) {
				get = true;
				hxd.Res.sfx.get_egg.play();

				var eg = new h2d.Bitmap(hxd.Res.mobs.toTile().sub(35, 149, 9, 11), game.s2d);
				eg.alpha = 0.8;
				eg.x = 5 + game.eggs * 13;
				eg.y = 5;
				game.eggs++;

				if( game.eggs == 5 )
					game.event.wait(1, game.win);

				game.event.waitUntil(function(dt) {
					spr.alpha -= 0.1 * dt;
					if( spr.alpha < 0 ) {
						remove();
						return true;
					}
					return false;
				});
			}
		}
	}

}