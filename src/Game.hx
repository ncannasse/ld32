import ent.Kind;
import hxd.Key in K;

class Game extends hxd.App {

	var speed = 1.;
	public var sx : Float = 0.;
	public var sy : Float = 0.;
	public var level : Level;
	public var hero : ent.Hero;
	public var frames : Map < String, Map < String, Array<h2d.Tile> > > ;
	public var entities : Array<ent.Entity>;
	public var key : { left : Bool, right : Bool, jump : Bool, action : Bool, actionPressed : Bool };
	public var event : hxd.WaitEvent;
	public var eggs = 0;
	public var hearts : Array<h2d.Bitmap>;
	var actionButton = false;
	var parts : h2d.SpriteBatch;
	var hparts : h2d.SpriteBatch;
	var envParts : h2d.SpriteBatch;
	var luciol : h2d.Tile;
	var title : h2d.Bitmap;
	var channel : hxd.snd.SoundChannel;

	override function init() {
		inst = this;
		initFrames();
		entities = [];
		event = new hxd.WaitEvent();
		s2d.setFixedSize(256, 240);
		level = new Level();
		level.init();

		hearts = [];
		for( i in 0...3 ) {
			var b = new h2d.Bitmap(s2d);
			b.x = 210 + i * 14;
			b.y = 5;
			b.alpha = 0;
			hearts.push(b);
		}

		var c = new hxd.snd.SoundData();
		c.loadURL("music.mp3");
		channel = c.playNative(0, true);

		parts = new h2d.SpriteBatch(hxd.Res.mobs.toTile());
		level.root.add(parts, 1);
		parts.hasUpdate = true;

		hparts = new h2d.SpriteBatch(hxd.Res.sprites.toTile());
		level.root.add(hparts, 1);
		hparts.hasUpdate = true;

		envParts = new h2d.SpriteBatch(hxd.Res.mobs.toTile());
		envParts.blendMode = Add;
		level.root.add(envParts, 2);

		luciol = envParts.tile.sub(16, 0, 16, 16, -8, -8);

		hero = new ent.Hero(level.startX, level.startY);
		hero.lock = true;
		sx = hero.x * 16 - 128;
		sy = (hero.y - 3) * 16 - 120;

		for( i in 0...30 ) {
			var p = new Part(luciol);
			envParts.add(p);
			var a = Math.random() * Math.PI * 2;
			var v = 0.01 + Math.random() * 0.03;
			p.vx = Math.cos(a) * v;
			p.vy = Math.sin(a) * v;
			p.time = Math.random() * 1000;
			p.x = sx + Std.random(s2d.width + 200) - 100;
			p.y = sy + Std.random(s2d.height + 200) - 100;
		}


		title = new h2d.Bitmap(hxd.Res.title.toTile(), level.root);
		title.y = sy;
		var int = new h2d.Interactive(s2d.width, s2d.height, s2d);
		var start = getText(s2d);
		start.text = "Click to start";
		start.x = Std.int((s2d.width - start.textWidth * start.scaleX) * 0.5);
		start.dropShadow.alpha = 0.6;
		start.y = 140;
		var time = 0.;
		event.waitUntil(function(dt) {
			time += dt/60;
			if( time > 0 ) {
				time -= 0.5;
				start.visible = !start.visible;
			}
			return start.parent == null;
		});
		int.onClick = function(_) {
			start.remove();
			int.remove();
			var acc = 0.;
			event.waitUntil(function(dt) {
				acc += 0.1 * dt;
				title.y -= acc * dt;
				if( title.y < sy - 120 ) {

					for( b in hearts ) b.alpha = 0.8;

					title.remove();
					title = null;
					hero.lock = false;

					return true;
				}
				return false;
			});
		};



	}

	public function win() {
		new h2d.Bitmap(h2d.Tile.fromColor(0, 256, 30), s2d).y = 98;
		var t = getText(s2d);
		t.textAlign = Center;
		t.text = "Congratulations ! You found the five eggs.\nYou can now get an haircut!\nmade in 48h for LD32 by @ncannasse";
		t.x = Std.int((s2d.width - t.textWidth * t.scaleX) * 0.5);
		t.y = 100;
		hero.lock = true;
	}

	public function restart() {
		hero.x = level.startX;
		hero.y = level.startY;
		hero.restart();
		level.restart();
		sx = hero.x * 16 - 128;
		sy = (hero.y - 1) * 16 - 120;
	}

	override function update(dt:Float) {

		#if debug
		if( K.isPressed("R".code) ) {
			speed = speed == 1 ? 0.1 : 1;
		}
		if( K.isPressed(K.BACKSPACE) )
			restart();
		if( K.isPressed("S".code) && K.isDown(K.CTRL) ) {
			level.startX = hero.x;
			level.startY = hero.y;
		}
		if( K.isPressed(K.SHIFT) )
			@:privateAccess hero.acc = -1;
		#end
		hxd.Timer.tmod *= speed;
		dt *= speed;

		key = {
			left : K.isDown(K.LEFT) || K.isDown("Q".code) || K.isDown("A".code),
			right : K.isDown(K.RIGHT) || K.isDown("D".code),
			jump : K.isDown(K.UP) || K.isDown("Z".code) || K.isDown("W".code),
			action : K.isDown(K.SPACE) || K.isDown("E".code) || K.isDown(K.CTRL),
			actionPressed : false,
		};
		if( key.action ) {
			if( !actionButton ) {
				actionButton = true;
				key.actionPressed = true;
			}
		} else
			actionButton = false;

		for( e in entities.copy() )
			e.update(dt);

		event.update(dt);
		level.update(dt);

		var tx = hero.x * 16 - 128;
		var ty = (Math.max(hero.y,hero.baseY) - 1) * 16 - 120;
		var p = Math.pow(0.9, dt);
		if( title == null ) {
			sx = sx * p + (1 - p) * tx;
			sy = sy * p + (1 - p) * ty;
		}
		if( sx < 0 ) sx = 0;
		if( sy < 0 ) sy = 0;
		if( sx + s2d.width > level.width * 16 ) sx = level.width * 16 - s2d.width;
		if( sy + s2d.height > level.height * 16 ) sy = level.height * 16 - s2d.height;

		var dx = level.scroll.x + sx;
		var dy = level.scroll.y + sy;
		level.scroll.x = -sx;
		level.scroll.y = -sy;

		var perlin = new hxd.Perlin();
		var f = Math.pow(0.95, dt);
		for( p in envParts.getElements() ) {
			var p = Std.instance(p, Part);
			p.time += dt;
			p.alpha = p.alpha * f + (1 - f) * ((Math.sin(p.time * 0.1) + 1) * 0.25 + 0.5);
			p.y += Math.cos(p.time * 0.03) * 0.04 * dt;
			p.x -= dx * 0.1;
			p.y -= dy * 0.1;
			var ax = p.x - sx;
			var ay = p.y - sy;
			if( ax < -100 || ay < -100 || ax > 356 || ay > 350 ) {
				p.x = sx + Math.random() * (s2d.width + 200) - 100;
				p.y = sy + Math.random() * (s2d.height + 200) - 100;
				p.alpha = 0;
			}
		}

		var m = hxd.Res.mobs.toTile();
		var tl = [m.sub(49, 149, 13, 11), m.sub(63,149,13,11)];
		for( i in 0...hearts.length ) {
			var h = hearts[i];
			h.tile = tl[hero.life > i ? 0 : 1];
		}

	}

	public function action() {
		if( key.actionPressed ) {
			key.actionPressed = false;
			return true;
		}
		return false;
	}

	public function getText(?parent) {
		var t = new h2d.Text(hxd.Res.font.toFont(), parent);
		t.scale(2 / 3);
		t.textColor = 0xF0F0F0;
		t.dropShadow = { dx : 1, dy : 1, color : 0, alpha : 0.4 };
		return t;
	}

	function initFrames() {
		frames = new Map();
		var a : Array<{ k : Kind, w : Int, h : Int, ?l : Array<Dynamic> }> = [
			{ k : Hero, w : 2, h : 2, l : ["default", 1, "blink", 1, "prerun", 1, "run", 3, "jump", 2, "attack", 2, "hair", 5, "catch", 3] },
			{ k : Rotator, w : 1, h : 1 },
			{ k : Npc, w : 1, h : 2 },
			{ k : Rock, w : 1, h : 1 },
			{ k : Spider, w : 2, h : 1, l : ["run", 3] },
			{ k : Jumper, w : 2, h : 2 },
			{ k : Bee, w: 2, h : 2, l : ["run", 3] },
			{ k : Egg, w : 2, h : 2 },
		];
		var tile = hxd.Res.sprites.toTile();
		var x = 0;
		var y = 0;
		for( inf in a ) {
			var anims = new Map();
			var w = inf.w * 16;
			var h = inf.h * 16;
			if( inf.l == null ) inf.l = ["default", 1];
			for( i in 0...inf.l.length >> 1 ) {
				var name : String = inf.l[i * 2];
				var count : Int = inf.l[i * 2 + 1];
				var tiles = [];
				var dw = w;
				switch( name ) {
				case "hair": dw = 5 * 16;
				case "catch":
					x = 0;
					y += h;
					h = 5 * 16;
				}
				for( n in 0...count ) {
					if( x + dw > 256 ) {
						x = 0;
						y += h;
					}
					tiles.push(tile.sub(x, y, dw, h, -(w >> 1), -h));
					x += dw;
				}
				if( name == "catch" ) {
					tiles[0].dy += 50;
					tiles[1].dy += 66;
					tiles[2].dy += 77;
				}
				if( name == "run" && count == 3 )
					tiles.push(tiles[1]);
				anims.set(name, tiles);
			}
			frames.set(inf.k.toString(), anims);
			y += h;
			x = 0;
			if( inf.k == Hero ) {
				tile = hxd.Res.mobs.toTile();
				x = 0;
				y = 0;
			}
		}
	}

	public function addPart( t : h2d.Tile, x : Float, y : Float, vx : Float, vy : Float, hero = false ) {
		var p = new Part(t);
		if( hero ) hparts.add(p) else parts.add(p);
		p.x = x * 16;
		p.y = y * 16;
		p.vx = vx * 16;
		p.vy = vy * 16;
	}

	public static var inst : Game;
	static function main() {
		#if debug
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		Std.instance(hxd.Res.loader.fs, hxd.fs.LocalFileSystem).createMP3 = true;
		hxd.Res.data.watch(function() {
			Data.load(hxd.Res.data.entry.getBytes().toString());
			inst.level.init();
		});
		#else
		hxd.Res.initEmbed({compressSounds:true});
		#end
		Data.load(hxd.Res.data.entry.getBytes().toString());
		new Game();
	}

}