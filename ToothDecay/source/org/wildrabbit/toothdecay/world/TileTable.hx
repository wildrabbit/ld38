package org.wildrabbit.toothdecay.world;

import flixel.FlxObject;
import haxe.ds.ArraySort;
import flixel.system.FlxAssets.FlxGraphicAsset;

class TileTable
{
	private var tileTable: Map<Int,TileInfo> = new Map<Int,TileInfo>();
	private var tileMappings: Array<Int> = null;
	private var sortedKeys: Array<Int> = new Array<Int>();	
	private var reverseMappings:Map<Int,Int> = new Map<Int, Int>();

	public function new()
	{		
	}
	
	public function iterator():Iterator<TileInfo>
	{
		return tileTable.iterator();
	}
	
	public function addEntry(value:TileInfo):Void
	{
		var needsAdd:Bool = !tileTable.exists(value.id);
		tileTable.set(value.id, value);		
		
		if (needsAdd)
		{
			sortedKeys.push(value.id);
			var comparer = function(v1:Int, v2:Int):Int
			{
				return v1 - v2;
			};
			ArraySort.sort(sortedKeys, comparer);
			if (!reverseMappings.exists(value.graphicId))
				reverseMappings.set(value.graphicId, value.id);
		}
	}
	
	public function emplaceEntry(id:Int, collisionType:Int, drillCost:Int, graphicId: Int, staminaCost:Int, parentId:Int, autoTiling:Bool = false):Void
	{
		var info:TileInfo = new TileInfo(id, collisionType, drillCost, graphicId, staminaCost, parentId, autoTiling);
		addEntry(info);
	}
	

	
	public function getInfo(key:Int):TileInfo
	{
		return tileTable.get(key);
	}
	
	public function clear():Void
	{
		for (key in tileTable.keys())
		{
			tileTable.remove(key);
		}
	}
	
	public function getTileMappings():Array<Int>
	{
		if (tileMappings == null)
		{
			buildTileMappings();
		}
		return tileMappings;
	}
	
	private function buildTileMappings():Void
	{
		tileMappings = new Array<Int>();
		for (key in sortedKeys)
		{
			if (key > 0 && key <= Grid.LAST_AUTOTILING_ID)
			{
				// We need to add all the references
				var graphicId:Int = tileTable[key].graphicId;
				for (offset in 0...Grid.TILE_STRIDE)
					tileMappings.push(graphicId + offset);
			}
			else 
			{
				tileMappings.push(tileTable[key].graphicId);	
			}			
		}
	}

	public function  getTypeFromGraphicId(graphicId:Int):Int
	{
		// First try: reverse map
		if (reverseMappings.exists(graphicId))
		{
			return reverseMappings[graphicId];
		}
		else 
		{
			var row:Int = Std.int((graphicId - 1) / Grid.TILE_STRIDE);
			var firstGraphicIdInStride = row * Grid.TILE_STRIDE + 1;
			if (reverseMappings.exists(firstGraphicIdInStride))
			{
				return reverseMappings[firstGraphicIdInStride];
			}
		}
		return 0;
	}
}