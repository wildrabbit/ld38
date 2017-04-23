package org.wildrabbit.toothdecay;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import org.wildrabbit.toothdecay.world.Grid;

/**
 * ...
 * @author ith1ldin
 */
class Pickup extends Entity
{
	public static inline var SUGAR:Int = 0;
	
	public var type:Int = 0;
	public var amount:Int = 10;
		
	public function new(grid:Grid, t:Int, a:Int, startRow:Int, startCol:Int) 
	{
		super(grid);
		type = t;
		amount = a;
		
		loadGraphic("assets/images/SUGAR.png");		
		
		setTile(startRow, startCol);
		centerToTile();
	}
	
	public function onPicked():Void
	{
		alive = false;
		deadSignal.dispatch(this);
	}
	
}