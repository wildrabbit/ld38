package org.wildrabbit.toothdecay.world;

import flash.geom.Transform;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSignal;
import org.wildrabbit.toothdecay.world.TransformedTile.TileTransformConfig;

/**
 * ...
 * @author ith1ldin
 */


typedef TileTransformConfig =
{
	var transformType:TileTransformType;
	var srcRow:Int;
	var srcCol:Int;
	var x:Float;
	var y:Float;
	var width:Int;
	var height:Int;
	var gfx:FlxGraphicAsset;
	var targetRow:Int;
	var targetCol:Int;
	var destinationID:Int;

}

class TransformedTile extends FlxSprite
{
	public var config: TileTransformConfig = null;
	public var transformFinished:FlxTypedSignal<TileTransformConfig -> Void>;
	
	public static function getTile(Config:TileTransformConfig):TransformedTile
	{
		if (pool.countLiving == poolSize)
		{
			trace("Pool is full!");
			return null;
		}
		
		var tile:TransformedTile = pool.recycle(TransformedTile);
		if (tile != null)
		{
			tile.reset(Config);
		}
		return tile;
	}
	
	private static inline var poolSize = 200;
	private static var pool:FlxTypedGroup<TransformedTile> = 
	{
		var elems = new FlxTypedGroup<TransformedTile>(MAX);
		for (i in 0...poolSize)
		{
			var t:TransformedTile = new TransformedTile();
			t.kill();
			elems.add(t);
		}
		elems;
	};
	
	public function new() 
	{
		super();
	}
	
	public function reset(Config: TileTransformConfig):Void
	{
		config = Config;
		if (config == null) return;
		
		var animated:Bool = config.animConfig != null && config.animConfig != "";
		
		loadGraphic(config.gfx, animated, config.width, config.height);
		setPosition(config.x, config.y);
		animation.destroyAnimations();
		
		if (animated)
		{
			animation.add(config.animName, config.frames, config.fps, config.bool);
		}			
	}
	
	public function start():Void
	{
		animation.play(config.animName);
		animation.finishCallback = OnAnimFinished;
	}
	
	public function OnAnimFinished(name:String):Void	
	{
		destroy();
		transformFinished(config);		
	}
	
}