package org.wildrabbit.toothdecay.world;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxTilemap;
import flixel.tile.FlxBaseTilemap;
/**
 * ...
 * @author ith1ldin
 */
class Grid extends FlxTilemap
{

	public function new() 
	{
		super();
		
	}
	
	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;
	
	// Replace with enum:
	public static inline var TILE_GAP:Int = 0;
	public static inline var TILE_BLUE:Int = 1;
	public static inline var TILE_YELLOW:Int = 2;
	public static inline var TILE_GREEN:Int = 3;
	public static inline var TILE_RED:Int = 4;
	public static inline var TILE_HARD:Int = 2;
	
	
	//
	private static inline var TILE_NEXTLEVEL:Int = 3;

	private var gridWidth:Int = 9;
	private var gridHeight:Int = 20;
	public  var tileWidth:Int = 64;
	public var tileHeight:Int = 64;
	
	private var camRef:FlxPoint = FlxPoint.get(0, 0);
	
	public function init():Void 
	{		
		var array:Array<Int> = 
		[
			0, 0, 0, 0, 0, 0, 0, 0,0,
			1, 4, 0, 0, 2, 2, 1, 2,3,
			5, 2, 2, 3, 4, 1, 0, 4,3,
			1, 3, 1, 3, 2, 2, 1, 4,3,
			4, 2, 3, 3, 4, 1, 0, 4,1,
			2, 2, 2, 1, 5, 4, 2, 3,2,
			0, 0, 5, 0, 4, 1, 0, 4,2,
			1, 2, 2, 3, 4, 1, 0, 0,0,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 4, 0, 2, 4, 1, 0, 4,5,
			3, 4, 0, 1, 2, 2, 1, 2,3,
			5, 2, 2, 3, 4, 1, 0, 4,3,
			1, 3, 1, 3, 2, 2, 1, 4,3,
			4, 2, 3, 3, 4, 1, 0, 4,1,
			2, 2, 2, 1, 5, 4, 2, 3,2,
			0, 0, 5, 0, 4, 1, 0, 4,2,
			1, 2, 2, 3, 4, 1, 0, 0,0,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 2, 2, 3, 4, 1, 0, 4,5
		];
		loadMapFromArray(array, gridWidth, gridHeight, "assets/images/tiles_00.png", TILE_WIDTH, TILE_HEIGHT, FlxTilemapAutoTiling.OFF, 0, 1, 1);
		setTileProperties(1, FlxObject.ANY);
		setTileProperties(2, FlxObject.ANY);
		setTileProperties(3, FlxObject.ANY);
		setTileProperties(4, FlxObject.ANY);
		setTileProperties(5, FlxObject.ANY);
	}
	
	public function getGridCoords(x:Float, y:Float, p:FlxPoint):Void
	{
		var xDelta:Float = x - this.x;
		var yDelta:Float = y - this.y;
		
		p.x = Math.floor(yDelta / tileHeight);
		p.y = Math.floor(xDelta / tileWidth);
	}
	
	public function getGridPosition(row:Int, col:Int, p:FlxPoint):Void
	{
		p.x = x + col * tileWidth;
		p.y = y + row * tileHeight;
	}
	
	public function drillTile(row:Int, col:Int):FlxSprite
	{
		setTile(col, row, TILE_GAP, true);
		// TODO: Convert to sprite for destruction animation.
		return null;
	}
	
	public function offsetCamRef(row:Int, col:Int):Void
	{
		camRef.set(col * tileWidth, row * tileHeight);
		// Tween cam. pos
	}
}