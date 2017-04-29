package org.wildrabbit.toothdecay.world;

import com.danielmessias.mazegenerator.DisjointSets;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tile.FlxTile;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import org.wildrabbit.toothdecay.Pickup;
import org.wildrabbit.toothdecay.PlayState;
import org.wildrabbit.toothdecay.world.TileInfo;
import org.wildrabbit.toothdecay.world.TileTable;

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

 @:enum
abstract TileType(Int) from Int to Int
{
	var Gap = 0;
    var Blue = 1;
    var Yellow = 2;
	var Green = 3;
	var Red = 4;
	var Hard = 5;
	var BlueTransform = 6;
	var YellowTransform = 7;
	var GreenTransform = 8;
	var RedTransform = 9;
	var HardTransform = 10;
	var EndLevel = 11;
	var EndLevelTransform = 12;
}
 
class Grid extends FlxTilemap
{
	private var parent:PlayState;
	
	public var tileTable:TileTable = new TileTable();
	public var tileHP:Array<Float> = new Array<Float>();
	
	public function new(Parent:PlayState) 
	{
		super();
		parent = Parent;
		setupTileTable();
	}
	
	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;
	
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
		setCustomTileMappings(tileTable.getTileMappings());
		loadMapFromArray(level, w, h, "assets/images/tiles_00.png", TILE_WIDTH, TILE_HEIGHT, FlxTilemapAutoTiling.OFF, 0, 1, 1);		
		var info:TileInfo = null;
		
		for (info in tileTable)
		{
			setTileProperties(info.id, info.collisionType);
		}		
		
		for (value in _data)
		{
			info = tileTable.getInfo(value);
			var msg:String = 'Invalid tile info for value $value!';
			if (info == null) throw msg;
			tileHP.push(info.drillCost);
		}
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
	
	private function setupTileTable():Void
	{
		tileTable.emplaceEntry(TileType.Gap, FlxObject.NONE, 0, 0,0, -1);
		tileTable.emplaceEntry(TileType.Blue, FlxObject.ANY, 1, 1,0, -1);
		tileTable.emplaceEntry(TileType.Yellow, FlxObject.ANY, 1, 2,0, -1);
		tileTable.emplaceEntry(TileType.Green, FlxObject.ANY, 1, 3,0,-1);
		tileTable.emplaceEntry(TileType.Red, FlxObject.ANY, 1, 4,0,-1);
		tileTable.emplaceEntry(TileType.Hard, FlxObject.ANY, 3,5,15, -1);
		tileTable.emplaceEntry(TileType.BlueTransform, FlxObject.NONE,0, 0,0, TileType.Blue);
		tileTable.emplaceEntry(TileType.YellowTransform, FlxObject.NONE, 0,0, 0, TileType.Yellow);
		tileTable.emplaceEntry(TileType.GreenTransform, FlxObject.NONE,0, 0,0, TileType.Green);
		tileTable.emplaceEntry(TileType.RedTransform, FlxObject.NONE,0, 0, 0,TileType.Red);
		tileTable.emplaceEntry(TileType.HardTransform, FlxObject.NONE,0, 0,0, TileType.Hard);
		tileTable.emplaceEntry(TileType.EndLevel, FlxObject.ANY, 1,6,0, -1);
		tileTable.emplaceEntry(TileType.EndLevelTransform, FlxObject.NONE, 1,0,0, TileType.EndLevel);
	}
	
	public function drillTile(row:Int, col:Int, strength:Float = 1):Int
	{
		var ourIdx: Int = col + row * widthInTiles;
		var label:Int = labels[ourIdx];	
		var tileType:Int = _data[ourIdx];
		var info:TileInfo = tileTable.getInfo(tileType);
		if (info == null) throw 'Invalid tile info for value $tileType';
		
		tileHP[ourIdx] -= strength;
		
		if (tileHP[ourIdx] <= 0)
		{
			tileHP[ourIdx] = 0;
		
				// Resolve transformed tile type:
		if (info.parentId >= 0)
		{
			tileType = info.parentId;
		}
			
		if (!Reg.resourceCounters.exists(tileType))
		{
			Reg.resourceCounters[tileType] = 0;
		}
		Reg.resourceCounters[tileType] = Reg.resourceCounters[tileType] + 1;
		setTile(col, row, TileType.Gap, true);
		
		
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
					var info:TileInfo = tileTable.getInfo(tileType);
					if (info == null) throw 'Invalid tile info for value $tileType';
					if (info.parentId >= 0)
					{
						tileType = info.parentId;
					}
					if (!Reg.resourceCounters.exists(tileType))
					{
						Reg.resourceCounters[tileType] = 0;
					}
					Reg.resourceCounters[tileType] = Reg.resourceCounters[tileType] + 1;
					setTileByIndex(tileIdx, TileType.Gap, true);
				}
			}			
		}
		clusterRebuildNeeded = true;
		// TODO: Convert to sprite for destruction animation.
		return info.staminaCost;	
		}
		return 0;
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
				if (tileValue == TileType.Gap) continue;
				
				// Test north:
				var northVal:Int = TileType.Gap;
				var westVal:Int = TileType.Gap;
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
			if (tileValue == TileType.Gap) continue;
				
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
				if (tileValue == TileType.Gap || !clusters.exists(labels[idx]) || clusters[labels[idx]].connected) continue;
				
				cluster = clusters[labels[idx]];
				var belowLabel:Int = labels[idx + widthInTiles];
				var belowTile:Int = _data[idx + widthInTiles];
				var predicate = function (pickup:Pickup):Bool { return pickup.tileRow == row + 1 && pickup.tileCol == col; };
				if ((belowTile == TileType.Gap && pickups.filter(predicate).length == 0)|| !clusters.exists(belowLabel) || !clusters[belowLabel].connected) continue;
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
					setTile(col,row, TileType.Gap);
					
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
	
	override private function initTileObjects():Void 
	{
		if (frames == null)
			return;
		
		_tileObjects = FlxDestroyUtil.destroyArray(_tileObjects);
		// Create some tile objects that we'll use for overlap checks (one for each tile)
		_tileObjects = new Array<FlxTile>();
		
		var length:Int = customTileRemap.length;
		length += _startingIndex;
		
		for (i in 0...length)
		{
			var info:TileInfo = tileTable.getInfo(i);
			if (info == null) continue;
			_tileObjects[i] = new FlxTile(this, i, _tileWidth, _tileHeight, (info.graphicId >= _drawIndex), (i >= _collideIndex) ? allowCollisions : FlxObject.NONE);
		}
		// Create debug tiles for rendering bounding boxes on demand
		#if FLX_DEBUG
		updateDebugTileBoundingBoxSolid();
		updateDebugTileBoundingBoxNotSolid();
		updateDebugTileBoundingBoxPartial();
		#end
	}
}