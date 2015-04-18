
class Level {

	var game : Game;
	var cols : Array<Bool>;
	var bg : h2d.TileGroup;
	var tgs : Array<h2d.TileGroup>;
	var time = 0.;
	var fog : h2d.TileGroup;
	var ents : Map<Int, ent.Entity>;
	public var root : h2d.Layers;

	public var width : Int;
	public var height : Int;

	public function new() {
		game = Game.inst;
		root = new h2d.Layers(game.s2d);
		ents = new Map();
	}

	public function collide( e : ent.Entity, x : Float, y : Float )  {
		if( x < 0 || x >= width || y < 0 || y >= height ) return true;
		return cols[Std.int(x) + Std.int(y) * width];
	}

	public function init() {

		if( tgs != null )
			for( t in tgs ) t.remove();
		tgs = [];

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
			switch( l.name ) {
			case "bg":
				bg = tg;
			case "fg":
				curLayer = 2;
			case "fog":
				fog = tg;
				tg.blendMode = Add;

				var m = new h3d.Matrix();
				m.identity();
				m.colorBrightness(-0.1);
				m.colorContrast(-0.05);
				m.colorHue(-0.1);
				var amb = new h2d.filter.Ambient(tg, m);
				amb.invert = true;
				root.filters = [amb];

			default:
			}
			tgs.push(tg);
			root.add(tg, curLayer);
			for( y in 0...height ) {
				for( x in 0...width ) {
					var v = d[x + y * width] - 1;
					if( v < 0 ) continue;
					tg.add(x * 16, y * 16, tiles[v]);
					if( hasCols ) cols[x + y * width] = true;
				}
			}
			var p = data.props.getLayer(l.name);
			if( p != null && p.mode == Ground ) {
				var tprops = data.props.getTileset(Data.levelData, l.data.file);
				var tbuild = new cdb.TileBuilder(tprops, t.width>>4, (t.width >> 4) * (t.height >> 4));
				var out = tbuild.buildGrounds(d, width);
				var i = 0;
				var max = out.length;
				while( i < max ) {
					var x = out[i++];
					var y = out[i++];
					var tid = out[i++];
					tg.add(x * 16, y * 16, tiles[tid]);
				}
			}
		}

		var old = [for( k in ents.keys() ) k => ents.get(k)];
		for( m in data.mobs ) {
			var id = m.x + m.y * width;
			if( ents.exists(id) ) {
				old.remove(id);
				continue;
			}
			var e : ent.Entity = switch( m.kind ) {
			default: new ent.Entity(m.kindId, m.x, m.y);
			};
			ents.set(id, e);
		}
		for( e in old ) e.remove();

		root.filters.push(new h2d.filter.Bloom(1,1.5,2,4,10));
	}

	public function update(dt:Float) {
		time += dt;
		bg.x = game.sx * 0.1;
		bg.y = game.sy * 0.1;
		fog.x = -game.sx * 0.95;
		fog.y = -game.sy * 0.95 + Math.sin(time * 0.02) * 3;
	}

}