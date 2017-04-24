package org.wildrabbit.toothdecay.world;

import com.danielmessias.mazegenerator.DisjointSets;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import org.wildrabbit.toothdecay.Pickup;
import org.wildrabbit.toothdecay.PlayState;

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
	private var parent:PlayState;
	public function new(Parent:PlayState) 
	{
		super();
		parent = Parent;
	}
	
	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;
	
	// Replace with enum:
	public static inline var TILE_GAP:Int = 0;
	
	public static inline var TILE_BLUE:Int = 1;
	public static inline var TILE_YELLOW:Int = 2;
	public static inline var TILE_GREEN:Int = 3;
	public static inline var TILE_RED:Int = 4;
	public static inline var TILE_HARD:Int = 5;
	
	public static inline var TILE_BLUE_REPL:Int = 6;
	public static inline var TILE_YELLOW_REPL:Int = 7;
	public static inline var TILE_GREEN_REPL:Int = 8;
	public static inline var TILE_RED_REPL:Int = 9;
	public static inline var TILE_HARD_REPL:Int = 10;
	
	public static inline var TILE_ENDLEVEL:Int = 11;
	
	//
	private static inline var TILE_NEXTLEVEL:Int = 3;

	public  var tileWidth:Int = TILE_WIDTH;
	public var tileHeight:Int = TILE_HEIGHT;
	
	private var camRef:FlxPoint = FlxPoint.get(0, 0);
	
	private var labels:Array<Int> = new Array<Int>();
	private var clusters:Map<Int,Cluster> = new Map<Int,Cluster>();
	
	public var tileDropped:FlxTypedSignal<Int->Int->Void> = new FlxTypedSignal<Int->Int->Void>();
	
	public var hardTiles:Map<Int, Float> = new Map<Int, Float>();	
	
	public var clusterRebuildNeeded:Bool = false;
	
	public function init(level:Array<Int>, w:Int, h: Int):Void 
	{		
		loadMapFromArray(level, w, h, "assets/images/tiles_00.png", TILE_WIDTH, TILE_HEIGHT, FlxTilemapAutoTiling.OFF, 0, 1, 1);
		setTileProperties(1, FlxObject.ANY);
		setTileProperties(2, FlxObject.ANY);
		setTileProperties(3, FlxObject.ANY);
		setTileProperties(4, FlxObject.ANY);
		setTileProperties(5, FlxObject.ANY);
		setTileProperties(6, FlxObject.ANY);
		setTileProperties(7, FlxObject.ANY);
		setTileProperties(8, FlxObject.ANY);
		setTileProperties(9, FlxObject.ANY);
		setTileProperties(10, FlxObject.ANY);		
		clusterRebuildNeeded = true;
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
		var ourIdx: Int = col + row * widthInTiles;
		var label:Int = labels[ourIdx];	
		var tileType:Int = _data[ourIdx];
		if (tileType > TILE_HARD)
		{
			tileType -= 5;
		}
			
		if (!Reg.resourceCounters.exists(tileType))
		{
			Reg.resourceCounters[tileType] = 0;
		}
		Reg.resourceCounters[tileType] = Reg.resourceCounters[tileType] + 1;
		setTile(col, row, TILE_GAP, true);
		
		
		if (clusters.exists(label))
		{
			if (clusters[label].indexes.length > 8)
			{
				camera.shake(0.01, 0.3);
				parent.showExtra();
			}
			for (tileIdx in clusters[label].indexes)
			{
				if (ourIdx != tileIdx)
				{
					var tileType:Int = _data[tileIdx];
					if (tileType > TILE_HARD)
					{
						tileType -= 5;
					}
					if (!Reg.resourceCounters.exists(tileType))
					{
						Reg.resourceCounters[tileType] = 0;
					}
					Reg.resourceCounters[tileType] = Reg.resourceCounters[tileType] + 1;
					setTileByIndex(tileIdx, TILE_GAP, true);
				}
				if (sprites != null && sprites.exists(tileIdx))
				{
					var sp:FlxSprite = sprites[tileIdx];
					sprites.remove(tileIdx);
					sp.destroy();					
				}
			}			
		}
		clusterRebuildNeeded = true;
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
		
		if (clusterRebuildNeeded)
		{
			clusterfuck(parent.pickupList);
			clusterRebuildNeeded = false;
		}
	}
	public function clusterfuck(pickups:Array<Pickup>):Void
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
					clusters[labels[idx]].indexes.push(idx);
				}
				else 
				{
					var c:Cluster = new Cluster();
					c.label = labels[idx];
					c.type = _data[idx];
					c.indexes.push(idx);
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
				var predicate = function (pickup:Pickup):Bool { return pickup.tileRow == row + 1 && pickup.tileCol == col; };
				if ((belowTile == TILE_GAP && pickups.filter(predicate).length == 0)|| !clusters.exists(belowLabel) || !clusters[belowLabel].connected) continue;
				cluster.connected = true;
			}
			row--;		
		}
		
		//checkConnections();
	}
	
	public function checkConnections():Void
	{
		if (sprites != null)
		{
			for (sp in sprites)
			{
				root.remove(sp);
				sp .destroy();
			}
		}
		
		sprites = new Map<Int,FlxSprite>();
		
		for (c in clusters)
		{
			if (!c.connected)
			{
				state = STATE_SHAKING;
				shakeStart = Date.now().getTime();
				
				for (tileIndex in c.indexes)
				{
					var sp:FlxSprite = tileToSprite(tileIndex % widthInTiles, Std.int(tileIndex / widthInTiles), _data[tileIndex] + 5);
					sp.ID = tileIndex;
					trace('$sp');
					sprites[tileIndex] = sp;
					root.add(sp);
				}
				
			}
			//trace(c.toString());
		}		
	}	
	
	public static inline var STATE_NONE:Int = 0;
	public static inline var STATE_SHAKING:Int = 1;
	public static inline var STATE_DESTROY:Int = 2;
	public static inline var STATE_DROPPING:Int = 3;
	
	
	public var state:Int = STATE_NONE;
	
	public var sprites:Map<Int,FlxSprite> = new Map<Int,FlxSprite>();
	public var shakeDelay:Float = 0.5;
	public var shakeStart:Float = -1;
	
	public var root:FlxTypedGroup<FlxSprite> = null;
	
	private function updateSprites(dt:Float):Void
	{
		if (state == STATE_SHAKING && shakeStart >= 0)
		{
			var elapsed:Float = (Date.now().getTime() - shakeStart) / 1000;
			if (elapsed > shakeDelay)
			{
				state == STATE_DROPPING;
				shakeStart = -1;
				for (k in sprites.keys())
				{
					var index: Int= k;
					var col:Int = index % widthInTiles;
					var row:Int = Std.int (index / widthInTiles);
					
					// Center:
					var coords:FlxPoint = getTileCoordsByIndex(index,false);
					sprites[index].x = coords.x;
					var restoredValue:Int = _data[index] - 5;
					setTile(col,row, TILE_GAP);
					
					var dropFinished = function(t:FlxTween):Void
					{
						if (row < heightInTiles - 1)
						{
							setTile(col, row + 1, restoredValue);
							tileDropped.dispatch(row + 1, col);
						}
					}
					FlxTween.tween(sprites[index], { "y": coords.y + tileHeight }, 0.5, { onComplete:dropFinished } );
				}
				var clearSprites = function(t:FlxTimer):Void
				{
					for (k in sprites.keys())
					{
						root.remove(sprites[k]);
						sprites[k].destroy();						
					}
					sprites = null;
					state = STATE_NONE;
				}
				new FlxTimer().start(0.6, clearSprites);
				
			}
			else 
			{
				for (sp in sprites.keys())
				{
					trace('shake ${sprites[sp].ID}');
					sprites[sp].x += FlxG.random.float( -2, 2);
				}
			}
		}
	}
		
	override private function autoTile(Index:Int):Void 
	{
		super.autoTile(Index);
	}	
}