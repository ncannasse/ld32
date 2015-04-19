package ent;

class Npc extends Entity {

	public function new(k, x, y) {
		super(k, x, y);
	}

	override function update(dt:Float) {
		super.update(dt);
		if( game.hero.x < x - 1 )
			spr.scaleX = -1;
		else if( game.hero.x > x + 1 )
			spr.scaleX = 1;
	}

	function textAppear( t : h2d.Text, onEnd : Void -> Void, speed = 0.5 ) {
		var text = t.splitText(t.text);
		t.text = "";
		var pos = 0., ipos = 0;
		game.event.waitUntil(function(dt) {
			pos += dt * speed;
			var p = Std.int(pos);
			if( p != ipos && ipos <= text.length ) {
				t.text = text.substr(0, p);
				ipos = p;
			}
			if( game.action() ) {
				if( p >= text.length ) {
					onEnd();
					return true;
				} else
					speed = 2;
			}
			return false;
		});
	}

	public function talk( texts : Array<String>, ?onEnd ) {
		function next() {
			var t = texts.shift();
			if( t == null ) {
				game.hero.lock = false;
				if( onEnd != null ) onEnd();
			} else {
				talNpcSeq(t, next);
			}
		}
		game.hero.lock = true;
		next();
	}

	function makeDialog( text : String, e : ent.Entity ) {
		var t = game.getText();
		t.maxWidth = 50;
		t.text = text;
		t.x = 5;
		t.y = 4;
		t.textColor = 0x404040;
		t.dropShadow.alpha = 0.1;
		while( t.textWidth / t.textHeight < 4 / 3 && t.maxWidth < 150 ) {
			t.maxWidth += 10;
			t.text = text;
		}
		var g = new h2d.ScaleGrid(hxd.Res.dialog.toTile(), 5, 5, game.level.scroll);
		g.width = Std.int(t.textWidth * t.scaleX + 10);
		g.height = Std.int(t.textHeight * t.scaleX + 6);
		g.x = Std.int(e.spr.x) - (g.width >> 1);
		g.y = Std.int(e.spr.y) - g.height - 28;
		g.addChild(t);

		var ti = new h2d.Bitmap(hxd.Res.dialogTick.toTile(), g);
		ti.x = (g.width >> 1) - 6;
		ti.y = g.height - 1;

		if( g.x < 5 ) {
			ti.x -= 5 - g.x;
			g.x = 5;
		}

		if( g.x + g.width > 330 ) {
			ti.x += g.x + g.width - 330;
			g.x = 330 - g.width;
		}
		return { g : g, t : t, ti : ti };
	}

	function talNpcSeq( text : String, onEnd : Void -> Void, ask = false ) {
		var e = this;
		var d = makeDialog(text, e);
		var g = d.g, t = d.t, ti = d.ti;

		g.alpha = ti.alpha = 0;
		t.visible = false;

		function hide() {
			game.event.waitUntil(function(dt) {
				g.alpha -= 0.1 * dt;
				t.alpha -= 0.1 * dt;
				ti.alpha -= 0.1 * dt;
				if( g.alpha < 0 ) {
					g.remove();
					return true;
				}
				return false;
			});
		}

		game.event.waitUntil(function(dt) {
			g.alpha = ti.alpha += 0.1 * dt;
			if( g.alpha > 1 ) {
				g.alpha = ti.alpha = 1;
				t.visible = true;
				textAppear(t, function() {
					hide();
					/*
					if( ask ) {
						var d = makeDialog("Yes\nNo", hero);
						var cursor = new h2d.Bitmap(hxd.Res.cursor.toTile(), d.g);
						var choice = true;
						var time = 0.;
						cursor.y = 2;
						waitUntil(function(dt) {
							time += dt;
							cursor.x = Math.sin(time * 0.3) - 4;
							if( K.isPressed(K.UP) || K.isPressed(K.DOWN) || K.isPressed("Z".code) || K.isPressed("W".code) || K.isPressed("S".code) ) {
								choice = !choice;
								Res.sfx.cursor.play();
								cursor.y = choice ? 2 : 12;
							}
							if( action() ) {
								answerResult = choice;
								if( choice ) Res.sfx.valid.play() else Res.sfx.cancel.play();
								cursor.remove();
								g.remove();
								g = d.g;
								t = d.t;
								ti = d.ti;
								hide();
								onEnd();
								return true;
							}
							return false;
						});
					} else*/ {
						onEnd();
					}
				});
				return true;
			}
			return false;
		});
	}

}