import ent.Kind;
import hxd.Key in K;

class Game extends hxd.App {

	public var level : Level;
	public var hero : ent.Hero;
	public var frames : Map < Kind, Map < String, Array<h2d.Tile> > > ;
	public var entities : Array<ent.Entity>;
	public var key : { left : Bool, right : Bool, jump : Bool };

	override function init() {
		inst = this;
		initFrames();
		entities = [];
		s2d.setFixedSize(256, 240);
		level = new Level();
		hero = new ent.Hero(10, 10);
	}

	override function update(dt:Float) {
		key = {
			left : K.isDown(K.LEFT) || K.isDown("Q".code) || K.isDown("A".code),
			right : K.isDown(K.RIGHT) || K.isDown("D".code),
			jump : K.isDown(K.UP) || K.isDown("Z".code) || K.isDown("W".code),
		};
		for( e in entities.copy() )
			e.update(dt);
	}

	function initFrames() {
		frames = new Map();
		var a : Array<{ k : Kind, w : Int, h : Int, l : Array<Dynamic> }> = [
			{ k : Hero, w : 2, h : 2, l : ["default", 1, "blink", 1, "skip", 1, "run", 3, "jump", 1] }
		];
		var tile = hxd.Res.sprites.toTile();
		var x = 0;
		var y = 0;
		for( inf in a ) {
			var anims = new Map();
			var w = inf.w * 16;
			var h = inf.h * 16;
			for( i in 0...inf.l.length >> 1 ) {
				var name : String = inf.l[i * 2];
				var count : Int = inf.l[i * 2 + 1];
				var tiles = [];
				for( n in 0...count ) {
					tiles.push(tile.sub(x, y, w, h, -(w >> 1), -h));
					x += w;
				}
				anims.set(name, tiles);
			}
			frames.set(inf.k, anims);
			y += h;
			x = 0;
		}
	}

	public static var inst : Game;
	static function main() {
		#if debug
		hxd.res.Resource.LIVE_UPDATE = true;
		#end
		hxd.Res.initEmbed();
		new Game();
	}

}