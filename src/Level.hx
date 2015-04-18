
class Level {

	var game : Game;
	public var root : h2d.Layers;

	public var width : Int;
	public var height : Int;

	public function new() {
		game = Game.inst;
		root = new h2d.Layers(game.s2d);
		width = 16;
		height = 15;
	}

	public function collide( x : Float, y : Float)  {
		if( x < 0 || x >= width || y < 0 || y >= height ) return true;
		return false;
	}

}