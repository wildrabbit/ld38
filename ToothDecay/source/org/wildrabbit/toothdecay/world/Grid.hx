package org.wildrabbit.toothdecay.world;

import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tile.FlxTile;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import org.wildrabbit.toothdecay.Pickup;
import org.wildrabbit.toothdecay.PlayState;
import org.wildrabbit.toothdecay.util.DisjointSet;
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
    var Enamel = 1;
    var Dentine = 2;
	var Cementum = 3;
	var Pulp = 4;
	var Filling = 5;
	var EnamelTransform = 6;
	var DentineTransform = 7;
	var CementumTransform = 8;
	var PulpTransform = 9;
	var FillingTransform = 10;
	var Nerve = 11;
	var NerveTransform = 12;
}
 
class Grid extends FlxTilemap
{
	private var parent:PlayState;
	
	public var tileTable:TileTable = new TileTable();
	public var tileHP:Array<Float> = new Array<Float>();
	
	public static inline var TILE_STRIDE:Int = 16;
	public static inline var LAST_AUTOTILING_ID:Int = TileType.Pulp;
	
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
	
	
	public function new(Parent:PlayState) 
	{
		super();
		parent = Parent;
		setupTileTable();
	}

	public function init(level:Array<Int>, w:Int, h: Int):Void 
	{		
		setCustomTileMappings(tileTable.getTileMappings());
		
		var conversion:Array<Int> = new Array<Int>();
		convert(level, conversion);
		loadMapFromArray(conversion, w, h, "assets/images/tiles_00.png", TILE_WIDTH, TILE_HEIGHT, AUTO);		
		var info:TileInfo = null;
		
		for (info in tileTable)
		{
			setTileProperties(info.graphicId, info.collisionType);
		}		
		
		for (value in _data)
		{
			info = tileTable.getInfo(resolveType(value));
			var msg:String = 'Invalid tile info for value $value!';
			if (info == null) throw msg;
			tileHP.push(info.drillCost);
		}
		clusterRebuildNeeded = true;
	}
	
	public function convert(values:Array<Int>, converted:Array<Int>):Void
	{
		converted.splice(0, converted.length);
		var tileInfo:TileInfo;
		for (key in values)
		{
			tileInfo = tileTable.getInfo(key);
			converted.push(tileInfo.graphicId);
		}
	}

	public function resolveType(graphicId:Int):TileType
	{
		return tileTable.getTypeFromGraphicId(graphicId);
		
	}
	public function resolveGraphicId(tileType:TileType):Int		
	{
		var tileInfo:TileInfo = tileTable.getInfo(tileType);
		if (tileInfo != null) return tileInfo.graphicId;
		else return -1;
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
		tileTable.emplaceEntry(TileType.Enamel, FlxObject.ANY, 1, 1,0, -1, true);
		tileTable.emplaceEntry(TileType.Dentine, FlxObject.ANY, 1, 17,0, -1, true);
		tileTable.emplaceEntry(TileType.Cementum, FlxObject.ANY, 1, 33,0,-1, true);
		tileTable.emplaceEntry(TileType.Pulp, FlxObject.ANY, 1, 49,0,-1, true);
		tileTable.emplaceEntry(TileType.Filling, FlxObject.ANY,5, 65,10, -1);
		tileTable.emplaceEntry(TileType.EnamelTransform, FlxObject.NONE,0, 0,0, TileType.Enamel);
		tileTable.emplaceEntry(TileType.DentineTransform, FlxObject.NONE, 0,0, 0, TileType.Dentine);
		tileTable.emplaceEntry(TileType.CementumTransform, FlxObject.NONE,0, 0,0, TileType.Cementum);
		tileTable.emplaceEntry(TileType.PulpTransform, FlxObject.NONE,0, 0, 0,TileType.Pulp);
		tileTable.emplaceEntry(TileType.FillingTransform, FlxObject.NONE,0, 0,0, TileType.Filling);
		tileTable.emplaceEntry(TileType.Nerve, FlxObject.ANY, 1,66,0, -1);
		tileTable.emplaceEntry(TileType.NerveTransform, FlxObject.NONE, 1,0,0, TileType.Nerve);
	}
	
	public function drillTile(row:Int, col:Int, strength:Float = 1):Int
	{
		var ourIdx: Int = col + row * widthInTiles;
		var label:Int = labels[ourIdx];	
		var graphicId:Int = _data[ourIdx];
		var tileType:Int = resolveType(graphicId);
		var info:TileInfo = tileTable.getInfo(tileType);
		var gapGraphicId:Int = tileTable.getInfo(TileType.Gap).graphicId;
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
			setTile(col, row, gapGraphicId, true);
		
		
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
						var tileType:Int = resolveType(_data[tileIdx]);
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
						setTileByIndex(tileIdx, gapGraphicId, true);
					}
				}			
			}
			clusterRebuildNeeded = true;
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
		
		var set:DisjointSet = new DisjointSet(len);

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
				tileValue = resolveType(_data[idx]);
				if (tileValue == TileType.Gap || tileValue == TileType.Filling) continue;
				
				// Test north:
				var northVal:Int = TileType.Gap;
				var westVal:Int = TileType.Gap;
				var northIdx:Int = -1;					
				var westIdx:Int = -1;

				if (row > 0)
				{
					northIdx = (row - 1) * widthInTiles + col;
					northVal = resolveType(_data[northIdx]);
				}
				
				if (col > 0)
				{
					westIdx = rowIdx + col - 1;
					westVal = resolveType(_data[westIdx]);
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
				else // Both neighbours have the same value
				{
					if (labels[northIdx] != labels[westIdx]) //However, they have different labels! merge
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
					c.type = resolveType(_data[idx]);
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
			tileValue = resolveType(_data[idx]);
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
				tileValue = resolveType(_data[idx]);
				if (tileValue == TileType.Gap || !clusters.exists(labels[idx]) || clusters[labels[idx]].connected) continue;
				
				cluster = clusters[labels[idx]];
				var belowLabel:Int = labels[idx + widthInTiles];
				var belowTile:Int = resolveType(_data[idx + widthInTiles]);
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
					setTile(col,row, tileTable.getInfo(TileType.Gap).graphicId);
					
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
			_tileObjects[i] = new FlxTile(this, i, _tileWidth, _tileHeight, (customTileRemap[i] >= _drawIndex), (i >= _collideIndex) ? allowCollisions : FlxObject.NONE);
		}
		// Create debug tiles for rendering bounding boxes on demand
		#if FLX_DEBUG
		updateDebugTileBoundingBoxSolid();
		updateDebugTileBoundingBoxNotSolid();
		updateDebugTileBoundingBoxPartial();
		#end
	}
	
	override private function applyCustomRemap():Void
	{
		var i:Int = 0;

		if (customTileRemap != null) 
		{
			while (i < totalTiles) 
			{
				var oldIndex = _data[i];
				var newIndex = oldIndex;
				if (oldIndex < customTileRemap.length)
				{
					newIndex = customTileRemap[oldIndex];
				}
				_data[i] = newIndex;
				i++;
			}
		}
	}
	

	
	override private function autoTile(Index:Int):Void
	{
		if (_data[Index] == 0)
		{
			return;
		}

		var type:Int = resolveType(_data[Index]);
		var tileInfo:TileInfo = tileTable.getInfo(type);
		if (tileInfo == null || !tileInfo.autoTiling) return;
		
		var refId:Int = tileInfo.graphicId;
		
		_data[Index] = 0;
		
		// UP
		if ((Index - widthInTiles < 0) || isTileCompatible(_data[Index - widthInTiles],type))
		{
			_data[Index] += 1;	// First on strip or there's something on top
		}
		// RIGHT
		if ((Index % widthInTiles >= widthInTiles - 1) || isTileCompatible(_data[Index + 1],type))
		{
			_data[Index] += 2;	// Last column or 
		}
		// DOWN
		if ((Std.int(Index + widthInTiles) >= totalTiles) || isTileCompatible(_data[Index + widthInTiles],type)) 
		{
			_data[Index] += 4;
		}
		// LEFT
		if ((Index % widthInTiles <= 0) || isTileCompatible(_data[Index - 1],type))
		{
			_data[Index] += 8;
		}
		
		// The alternate algo checks for interior corners
		if ((auto == ALT) && (_data[Index] == 15))
		{
			// BOTTOM LEFT OPEN
			if ((Index % widthInTiles > 0) && (Std.int(Index + widthInTiles) < totalTiles) && (_data[Index + widthInTiles - 1] <= 0))
			{
				_data[Index] = 1;
			}
			// TOP LEFT OPEN
			if ((Index % widthInTiles > 0) && (Index - widthInTiles >= 0) && (_data[Index - widthInTiles - 1] <= 0))
			{
				_data[Index] = 2;
			}
			// TOP RIGHT OPEN
			if ((Index % widthInTiles < widthInTiles - 1) && (Index - widthInTiles >= 0) && (_data[Index - widthInTiles + 1] <= 0))
			{
				_data[Index] = 4;
			}
			// BOTTOM RIGHT OPEN
			if ((Index % widthInTiles < widthInTiles - 1) && (Std.int(Index + widthInTiles) < totalTiles) && (_data[Index + widthInTiles + 1] <= 0))
			{
				_data[Index] = 8;
			}
		}
		
		_data[Index] += refId;
	}
	
	public function isTileCompatible(graphicId:Int, refType:Int):Bool
	{
		return resolveType(graphicId) == refType;
	}
}