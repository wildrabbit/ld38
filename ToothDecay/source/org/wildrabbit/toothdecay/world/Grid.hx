package org.wildrabbit.toothdecay.world;

import com.danielmessias.mazegenerator.DisjointSets;

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
	
	private var labels:Array<Int> = new Array<Int>();
	private var clusters:Map<Int,Cluster> = new Map<Int,Cluster>();
	
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
		var label:Int = labels[row * widthInTiles + col];
		setTile(col, row, TILE_GAP, true);
		
		if (clusters.exists(label))
		{
			for (tileIdx in clusters[label].indexes)
			{
				setTileByIndex(tileIdx, TILE_GAP, true);
			}			
		}
		// TODO: Convert to sprite for destruction animation.
		return null;
	}
	
	public function offsetCamRef(row:Int, col:Int):Void
	{
		camRef.set(col * tileWidth, row * tileHeight);
		// Tween cam. pos
	}
	
	override public function update(dt:Float):Void
	{
		super.update(dt);		
	}
	public function clusterfuck(playerRow:Int, playerCol:Int):Void
	{
		clusters = new Map<Int,Cluster>();
		labels.splice(0, labels.length);
		var len: Int = _data.length;
		
		var set:DisjointSets = new DisjointSets(len);

		var nextLabel:Int = -1;
		for (dataIdx in 0...len)
		{
			labels.push(0);			
		}
		var rowIdx:Int = 0;
		var idx:Int = 0;
		nextLabel = 0;
		
		var tileValue:Int = -1;
		
		// First pass
		for (row in 0...heightInTiles)
		{
			rowIdx = row * widthInTiles;
			for (col in 0...widthInTiles)
			{
				idx = rowIdx + col;
				tileValue = getTileByIndex(idx);
				if (tileValue == TILE_GAP) continue;
				
				// Test north:
				var northVal:Int = TILE_GAP;
				var westVal:Int = TILE_GAP;
				var northIdx:Int = -1;					
				var westIdx:Int = -1;

				if (row > 0)
				{
					northIdx = (row - 1) * widthInTiles + col;
					northVal = _data[northIdx];
				}
				
				if (col > 0)
				{
					westIdx = rowIdx + col - 1;
					westVal = _data[westIdx];
				}
				
				// Both are gaps: create new label
				if (westVal != tileValue && northVal != tileValue)
				{
					labels[idx] = ++nextLabel;
				}
				else if (westVal == tileValue && northVal != tileValue)
				{
					labels[idx] = labels[westIdx];
				}
				else if (westVal != tileValue && northVal == tileValue)
				{
					labels[idx] = labels[northIdx];
				}
				else 
				{
					if (labels[northIdx] != labels[westIdx])
					{
						labels[idx] = Std.int(Math.min(labels[northIdx], labels[westIdx]));
						set.union(labels[northIdx], labels[westIdx]);
					}
					else 
					{
						labels[idx] = labels[westIdx];
					}
				}
			}
		}
		
		// Second pass
		//var sb:StringBuf;
		for (row in 0...heightInTiles)
		{
			//sb = new StringBuf();
			rowIdx = row * widthInTiles;
			for (col in 0...widthInTiles)
			{
				idx = rowIdx + col;
				labels[idx] = set.find(labels[idx]);
				if (labels[idx] == 0) continue;
				
				if (clusters.exists(labels[idx]))
				{
					clusters[labels[idx]].indexes.add(idx);
				}
				else 
				{
					var c:Cluster = new Cluster();
					c.label = labels[idx];
					c.type = _data[idx];
					c.indexes.add(idx);
					clusters.set(labels[idx], c);
				}
				//sb.add(Std.string(labels[idx]));
				//sb.add(col == widthInTiles - 1 ? '\n' : ',');
			}
			//trace(sb.toString());			
		}
		
		// Third pass: Check for disconnected clusters
		rowIdx = widthInTiles * (heightInTiles - 1);
		for (col in 0...widthInTiles)
		{
			idx = rowIdx + col;
			tileValue = _data[idx];
			if (tileValue == TILE_GAP) continue;
				
			if (clusters.exists(labels[idx]))
			{
				clusters[labels[idx]].connected = true;
			}
		}
		var row:Int = heightInTiles - 2;
		var cluster:Cluster = null;
		while (row >= 0)
		{
			rowIdx = row * widthInTiles;
			for (col in 0...widthInTiles)
			{
				idx = rowIdx + col;
				tileValue = _data[idx];
				if (tileValue == TILE_GAP || !clusters.exists(labels[idx]) || clusters[labels[idx]].connected) continue;
				
				cluster = clusters[labels[idx]];
				var belowLabel:Int = labels[idx + widthInTiles];
				var belowTile:Int = _data[idx + widthInTiles];
				if (belowTile == TILE_GAP || !clusters.exists(belowLabel) || !clusters[belowLabel].connected) continue;
				cluster.connected = true;
			}
			row--;		
		}
		
/*		for (c in clusters)
		{
			trace(c.toString());
		}*/
	}
}