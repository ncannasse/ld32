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
	var actionButton = false;
	var parts : h2d.SpriteBatch;
	var hparts : h2d.SpriteBatch;

	override function init() {
		inst = this;
		initFrames();
		entities = [];
		event = new hxd.WaitEvent();
		s2d.setFixedSize(256, 240);
		level = new Level();
		level.init();

		parts = new h2d.SpriteBatch(hxd.Res.mobs.toTile());
		level.root.add(parts, 1);
		parts.hasUpdate = true;

		hparts = new h2d.SpriteBatch(hxd.Res.sprites.toTile());
		level.root.add(hparts, 1);
		hparts.hasUpdate = true;

		hero = new ent.Hero(level.startX, level.startY);
		sx = hero.x * 16 - 128;
		sy = (hero.y - 1) * 16 - 120;
	}

	public function restart() {
		hero.x = level.startX;
		hero.y = level.startY;
		hero.restart();
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
		sx = sx * p + (1 - p) * tx;
		sy = sy * p + (1 - p) * ty;
		if( sx < 0 ) sx = 0;
		if( sy < 0 ) sy = 0;
		if( sx + s2d.width > level.width * 16 ) sx = level.width * 16 - s2d.width;
		if( sy + s2d.height > level.height * 16 ) sy = level.height * 16 - s2d.height;
		level.scroll.x = -sx;
		level.scroll.y = -sy;
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
		var c = new hxd.snd.SoundData();
		c.loadURL("music.mp3");
		var channel = c.playNative(0, true);
		Data.load(hxd.Res.data.entry.getBytes().toString());
		new Game();
	}

}