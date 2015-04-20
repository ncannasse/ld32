package ent;

class Hero extends Entity {

	var hitDebug : h2d.Bitmap;
	var hairBounds : h2d.col.Bounds;
	var catchDist : Float;
	var catchSpeed : Float;
	var canJump = true;
	var hitRecovery = 0.;
	var hitList : Array<Entity>;
	public var lock = false;
	public var baseY : Float;

	public function new(x,y) {
		super(Hero, x, y);
		feets = 20;
		life = game.hearts.length;
		hairBounds = new h2d.col.Bounds();
		hitDebug = new h2d.Bitmap(h2d.Tile.fromColor(0xFF00FF, 1, 16), spr);
		hitDebug.y = - 16;
	}

	override function destroy() {
		super.destroy();
		hxd.Res.sfx.hero_die.play();
		game.event.wait(1.5, function() if( isRemoved() && game.hero == this ) game.restart());
	}

	public function restart() {
		add();
		life = game.hearts.length;
		acc = 0;
		accX = 0;
		lock = false;
		gravity = true;
		state = Jump;
		hitRecovery = 1;
	}

	override function getBounds() {
		if( state == Catch ) {
			var b = new h2d.col.Bounds();
			b.addPoint(spr.localToGlobal(new h2d.col.Point(-0.2, (catchDist + 1) * 16)));
			b.addPoint(spr.localToGlobal(new h2d.col.Point(0.2, (catchDist + 1) * 16)));
			b.addPoint(spr.localToGlobal(new h2d.col.Point(-0.2, (catchDist - 0.25) * 16)));
			b.addPoint(spr.localToGlobal(new h2d.col.Point(0.2, (catchDist - 0.25) * 16)));

			b.offset( -x * 16, -y * 16 );
			b.xMin /= 16;
			b.xMax /= 16;
			b.yMin /= 16;
			b.yMax /= 16;
			return b;
		}
		return super.getBounds();
	}

	override public function hit(by:Entity) {
		if( lock || hitRecovery > 0 ) return;
		if( state == Catch ) {
			catchEnd();
			if( state == Catch ) return;
		}
		hitRecovery = 2;
		push( x < by.x ? -2 : 2, -0.2 );
		hxd.Res.sfx.hero_hurt.play();
		life--;
		if( life <= 0 ) destroy();
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

	override function play(anim, ?onEnd) {
		super.play(anim, onEnd);
		var s = hxd.Res.sfx;
		switch( anim ) {
		case "attack": s.hair.play();
		case "hair_rev": s.hair_rev.play();
		default:
		}
	}

	override function set_state(s:Entity.State) {
		switch( s ) {
		case Stand:
			accX = 0;
			baseY = y;
			if( acc == 0 ) canJump = true;
		case Attack:
			hitList = [];
			state = s;
			play("attack", function() play("hair", function() play("hair_rev", function() play("attack_rev", function() state = Stand))));
			return s;
		default:
		}
		return super.set_state(s);
	}

	public function catchRot( e : Entity ) {
		var frame = anim == "hair" ? spr.currentFrame : spr.frames.length - spr.currentFrame;
		var p = getHitPos();
		state = Catch;
		gravity = false;
		canPush = false;
		spr.speed = 0;
		frame--;
		baseY = e.y - 0.5 + p/16 + 2;
		catchDist = p;
		catchSpeed = 0;
		if( frame < 0 ) frame = 0;
		if( frame > 2 ) frame = 2;
		spr.currentFrame = frame;
		spr.rotation = Math.atan2((e.y - 0.5) - y, e.x - x) + Math.PI / 2;
		acc = 0;
		x = e.x;
		y = e.y - 0.5;
	}

	function getHitPos() {
		var frame = anim == "hair" ? spr.currentFrame : spr.frames.length - spr.currentFrame;
		return (Math.min(frame,4) + 1) * 0.75;
	}

	function catchEnd() {

		var f = spr.getFrame();
		var a = spr.rotation;
		var dist = (f.height + f.dy) / 16;

		if( collide( -dist * Math.sin(a), dist * Math.cos(a)) )
			return;

		state = Jump;
		gravity = true;
		acc = 0;
		canPush = true;
		x -= dist * Math.sin(a);
		y += dist * Math.cos(a);

		if( y < height / 16 ) y = height / 16;

		var pow = Math.sqrt(Math.abs(catchSpeed)) * (0.1 + Math.abs(Math.sin(a))) * 5 * Math.sqrt(dist);

		var dx = Math.cos(a + Math.PI) * pow * (catchSpeed < 0 ? -1 : 1) - Math.sin(a) * 3;
		var dy = Math.sin(a + Math.PI) * pow * (catchSpeed < 0 ? -1 : 1) + Math.cos(a) * 3;

		var outA = Math.atan2(dy, dx);
		var mx = Math.cos(outA) * pow;
		var my = Math.sin(outA) * pow;
		if( my > 0 ) my = 0 else my = -Math.sqrt( -my * 0.15) - 0.05;
		push(mx, my);
		hxd.Res.sfx.yeepee.play();
	}

	override function update(dt:Float) {
		super.update(dt);

		if( hitRecovery > 0 ) {
			hitRecovery -= dt / 60;
			if( hitRecovery <= 0 )
				spr.visible = true;
			else
				spr.visible = Math.sin(hitRecovery * 60) > 0;
		}

		var moving = false;
		if( state != Catch && !lock ) {
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
			if( spr.rotation != 0 ) {
				var pt = spr.localToGlobal(new h2d.col.Point(0, 16));
				spr.rotation = hxd.Math.angleMove(spr.rotation, 0, 0.2 * dt / (Math.max(1, Math.abs(accX * 2))));
				var pt2 = spr.localToGlobal(new h2d.col.Point(0, 16));
				pt2.x -= pt.x;
				pt2.y -= pt.y;
				move(-pt2.x / 16, -pt2.y / 16);
			}
		}

		height = 24;
		hitDebug.visible = false;
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

			if( anim == "hair" || anim == "hair_rev" ) {
				var p = getHitPos();
				//hitDebug.visible = true;
				hitDebug.x = p * 16;
				hairBounds.set(0, -19 / 16, p, 13 / 16);
				if( spr.scaleX < 0 ) {
					hairBounds.xMin -= hairBounds.width;
					hairBounds.xMax = 0;
				}
				for( e in game.entities.copy() )
					if( e != this && e.checkHit(this, hairBounds) && hitList.indexOf(e) < 0 ) {
						hitList.push(e);
						e.hit(this);
					}
			}
		case Catch:

			if( lock ) return;

			spr.rotation = hxd.Math.angle(spr.rotation + catchSpeed * 0.5 * dt);
			var a = spr.rotation;

			var fx = -catchSpeed * Math.sin(a);
			var fy = catchSpeed * Math.cos(a) + 0.03;
			var ta = Math.atan2(fy, fx);
			var pa = Math.pow(0.99, dt);
			var newa = a * pa + (1 - pa) * ta;
			catchSpeed *= Math.pow(0.96, dt);
			var da = -Math.sin(newa) * 0.01;

			if( game.key.right ) {
				spr.scaleX = 1;
				if( da * Math.cos(a) < 0 ) {
					if( catchSpeed < 0 ) catchSpeed *= Math.pow(1.07, dt);
					da -= 0.005;
				} else
					da *= 0.5;
			} else if( game.key.left ) {
				spr.scaleX = -1;
				if( da * Math.cos(a) > 0 ) {
					if( catchSpeed > 0 ) catchSpeed *= Math.pow(1.07, dt);
					da += 0.005;
				}
				else
					da *= 0.5;
			}

			catchSpeed += da * dt;

			if( game.key.actionPressed ) {
				catchEnd();
				game.key.actionPressed = false;
			}
		default:
		}

		if( lock ) return;

		if( state == Stand && game.key.jump && canJump ) {
			state = Jump;
			hxd.Res.sfx.jump.play();
			canJump = false;
			acc = -0.38;
		} else if( (state == Stand || state == Jump) && game.key.actionPressed ) {

			var bounds = getBounds().clone();
			bounds.offset(spr.scaleX, 0);
			if( spr.scaleX > 0 )
				bounds.xMax -= 0.25;
			else
				bounds.xMin += 0.25;
			for( e in game.entities )
				if( e.checkHit(this, bounds) ) {
					switch( e.kind ) {
					case Npc:
						var text = switch( [Std.int(e.x) , Std.int(e.y - 0.1)] ) {
						case [13, 87]:
							["If you are stuck, use your head!", "With your hairstyle, you could even break rocks!"];
						case [6, 73]:
							["You might want to put your hair into pikes.", "Maybe it hurts, maybe it's goooood."];
						case [28, 80]:
							["Dino eggs are you looking for?", "Five of them in the forest there is."];
						case [54, 96]:
							["The only way is up.", "Be careful of killer bees."];
						case [71, 83]:
							["It looks dangerous.", "But you have strong hair, don't you?" ];
						default:
							["???"];
						}
						game.level.startX = x;
						game.level.startY = y;
						Std.instance(e, Npc).talk(text);
						return;
					default:
					}
				}

			push(spr.scaleX * 0.12, state == Jump ? 0 : -0.05);
			state = Attack;
		}

		if( Math.abs(y - baseY) > 5 ) {
			if( baseY < y ) baseY = y - 5 else baseY = y + 5;
		}

		if( game.level.getCollide(x, y - 0.1) == Die && y - Std.int(y-0.1) > 0.8 )
			destroy();

	}

}