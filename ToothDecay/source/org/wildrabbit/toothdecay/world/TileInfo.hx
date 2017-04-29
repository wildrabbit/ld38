package org.wildrabbit.toothdecay.world;
import flixel.FlxObject;
import haxe.ds.ArraySort;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * ...
 * @author ith1ldin
 */

@:enum
abstract TileTransformType(Int) from Int to Int
{
    var Destroy = 0;
    var Shake = 1;
    var Drop = 2;
	var NumEntries = Drop - Destroy + 1;
}

 typedef TransformStateConfig =
 {
	var transformType:TileTransformType;
	var transformedTileId:Int;
	
	var gfx:FlxGraphicAsset;
	@:optional var animationName:String;
	@:optional var frames:Array<Int>;
	@:optional var fps:Int;
	@:optional var loop:Bool;
 }

class TileInfo
{
	static public var NO_TILE:TileInfo = new TileInfo( -1, -1, -1);
	public var id:Int = 0;
	public var graphicId:Int = 0;
	public var collisionType:Int = FlxObject.NONE;
	public var drillCost:Int = 0;
	public var staminaCost:Int = 0;
	public var parentId:Int = 0;
	public var transformationConfigs:Map<TileTransformType, TransformStateConfig> = new Map<TileTransformType, TransformStateConfig>();
		
	public function new(Id:Int, CollisionType:Int, DrillCost:Int, GraphicId:Int = -1, StaminaCost:Int = 0, ParentId:Int = -1) 
	{
		set(Id, CollisionType, DrillCost, GraphicId, StaminaCost, ParentId);
	}	
	
	public function setTransformationData(cfg:TransformStateConfig):Void
	{
		transformationConfigs[cfg.transformType] = cfg;
	}
	public function getTransformationData(type:TileTransformType):TransformStateConfig
	{
		if (transformationConfigs.exists(type))
		{
			return transformationConfigs[type];
		}
		return null;
	}
	
	public function set(Id:Int, CollisionType:Int, DrillCost:Int, GraphicId:Int = -1, StaminaCost:Int = 0,  ParentId:Int = -1):Void
	{
		id = Id;
		collisionType = CollisionType;
		drillCost = DrillCost;
		staminaCost = StaminaCost;
		parentId = ParentId;
		graphicId = id;
		
		if (GraphicId >= 0)
			graphicId = GraphicId;
	}
}
