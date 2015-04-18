
class Level {

	var game : Game;
	var cols : Array<Bool>;
	public var root : h2d.Layers;

	public var width : Int;
	public var height : Int;

	public function new() {
		game = Game.inst;
		root = new h2d.Layers(game.s2d);
		init();
	}

	public function collide( e : ent.Entity, x : Float, y : Float )  {
		if( y < 0 ) return false;
		if( x < 0 || x >= width || y >= height ) return true;
		return cols[Std.int(x) + Std.int(y) * width];
	}

	function init() {
		var data = Data.levelData.all[0];
		width = data.width;
		height = data.height;
		cols = [];
		var t = hxd.Res.tiles.toTile();
		var tiles = t.grid(16);
		var curLayer = 0;
		for( l in data.layers ) {
			var d = l.data.data.decode();
			var tg = new h2d.TileGroup(t);
			var hasCols = l.name == "platforms";
			root.add(tg, curLayer);
			for( y in 0...height ) {
				for( x in 0...width ) {
					var v = d[x + y * width] - 1;
					if( v < 0 ) continue;
					tg.add(x * 16, y * 16, tiles[v]);
					if( hasCols ) cols[x + y * width] = true;
				}
			}
		}
	}

}