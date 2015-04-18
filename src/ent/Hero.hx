package ent;

class Hero extends Entity {

	var hit : h2d.Bitmap;
	var hairBounds : h2d.col.Bounds;
	var catchDist : Float;

	public function new(x,y) {
		super(Hero, x, y);
		feets = 20;
		hairBounds = new h2d.col.Bounds();
		hit = new h2d.Bitmap(h2d.Tile.fromColor(0xFF00FF, 1, 16), spr);
		hit.y = - 16;
	}

	override function getSpeed(anim:String) {
		return switch( anim ) {
		case "blink": 7;
		case "run", "prerun": 10;
		case "attack", "attack_rev": 40;
		case "hair", "hair_rev": 80;
		default: super.getSpeed(anim);
		}
	}

	override function set_state(s:Entity.State) {
		switch( s ) {
		case Attack:
			state = s;
			play("attack", function() play("hair", function() play("hair_rev", function() play("attack_rev", function() state = Stand))));
		default:
			return super.set_state(s);
		}
		return s;
	}

	override function update(dt:Float) {
		super.update(dt);


		var moving = false;
		if( state != Catch ) {
			if( game.key.left ) {
				spr.scaleX = -1;
				moveX( -0.12 * dt);
				moving = true;
			}
			if( game.key.right ) {
				spr.scaleX = 1;
				moveX(0.12 * dt);
				moving = true;
			}
			spr.rotation = hxd.Math.angleMove(spr.rotation, 0, 0.2 * dt);
		}

		height = 24;
		hit.visible = false;
		switch( state ) {
		case Stand:
			if( anim == "default" && !moving && randt() < 0.03 ) play("blink", function() play("default"));
			if( moving ) {
				if( anim != "run" ) play("prerun", function() play("run"));
			} else if( anim == "run" )
				play("default");
		case Jump:
			height = 28;
			if( acc < 0 && !game.key.jump )
				acc *= Math.pow(0.9, dt);
		case Attack:
			if( !game.key.action ) {
				if( anim != "attack_rev" && anim != "hair_rev" )
					play("attack_rev", function() state = Jump);
			}
			if( anim == "hair" || anim == "hair_rev" ) {
				var frame = anim == "hair" ? spr.currentFrame : spr.frames.length - spr.currentFrame;
				var p = (frame + 1) * 0.7;
				hairBounds.set(0, -19 / 16, p, 13 / 16);
				if( spr.scaleX < 0 ) hairBounds.xMin -= hairBounds.width;
				for( e in game.entities )
					if( e.checkHit(this, hairBounds) ) {
						switch( e.kind ) {
						case Rotator:
							state = Catch;
							gravity = false;
							spr.speed = 0;
							frame--;
							catchDist = p;
							if( frame < 0 ) frame = 0;
							if( frame > 2 ) frame = 2;
							spr.currentFrame = frame;
							height = p;
							spr.rotation = Math.atan2((e.y - 0.5) - y, e.x - x) + Math.PI / 2;
							x = e.x;
							y = e.y - 0.5;
						default:
						}
					}
			}
		case Catch:
			spr.rotation += 0.05 * dt;
			spr.rotation = hxd.Math.angle(spr.rotation);
			if( game.key.actionPressed ) {
				state = Jump;
				gravity = true;
				var a = spr.rotation - Math.PI / 2;
				x -= catchDist * Math.cos(a);
				y -= catchDist * Math.sin(a);
				game.key.actionPressed = false;
			}
		default:
		}

		if( state == Stand && game.key.jump ) {
			state = Jump;
			acc = -0.45;
		} else if( (state == Stand || state == Jump) && game.key.actionPressed ) state = Attack;
	}

}