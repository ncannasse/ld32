package ent;

class Hero extends Entity {

	public function new(x,y) {
		super(Hero, x, y);
		feets = 9;
		height = 24;
	}

	override function getSpeed(anim:String) {
		return switch( anim ) {
		case "blink": 7;
		default: super.getSpeed(anim);
		}
	}

	override function update(dt:Float) {
		super.update(dt);
		if( anim == "default" && randt() < 0.03 ) play("blink", function() play("default"));
		if( acc < 0 && !game.key.jump )
			acc *= Math.pow(0.9, dt);
		if( (anim == "default" || anim == "run") && game.key.jump ) {
			play("jump");
			acc = -0.45;
		}
		if( game.key.left ) {
			spr.scaleX = -1;
			moveX( -0.1 * dt);
		}
		if( game.key.right ) {
			spr.scaleX = 1;
			moveX(0.1 * dt);
		}
		if( anim != "jump" && (game.key.left || game.key.right) ) {
			if( anim != "run" ) play("run");
		} else if( anim == "run" )
			play("default");
	}

}