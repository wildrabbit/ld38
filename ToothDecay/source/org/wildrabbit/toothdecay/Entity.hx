package org.wildrabbit.toothdecay;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSignal;
import org.wildrabbit.toothdecay.world.Grid;

/**
 * ...
 * @author ith1ldin
 */
class Entity extends FlxSprite
{
	private var gridRef:Grid;
	public var deadSignal: FlxTypedSignal<Entity->Void>;
	
	private var fallSpeed:Float = 500;
	private var gravity:Float = 500;
	
	public var tileCol:Int = 0;
	public var tileRow:Int = 0;
	
	public function new(grid:Grid) 
	{
		super(0, 0);
		gridRef = grid;
		
		acceleration.y = 800;
		deadSignal = new FlxTypedSignal<Entity->Void>();
	}
	
	override public function update(dt:Float):Void
	{
		super.update(dt);
	}
	
	public function centerToTile():Void
	{
		var p:FlxPoint = FlxPoint.weak();
		gridRef.getGridPosition(tileRow, tileCol, p);
		p.x += 0.5*(gridRef.tileWidth - width);			
		setPosition(p.x, p.y + gridRef.tileHeight - height);
		p.putWeak();
	}
	public function setTile(row:Int, col:Int, ?alignRight:Bool= false):Void
	{
		var p:FlxPoint = FlxPoint.weak();
		gridRef.getGridPosition(row, col, p);
		if (alignRight)
		{
			p.x += gridRef.tileWidth - width;			
		}		
		setPosition(p.x, p.y + gridRef.tileHeight - height);
		p.putWeak();
	}

	public function keepBounds():Void
	{
		x = FlxMath.bound(x, 0, gridRef.width - width);
		y = FlxMath.bound(y, 0, FlxG.worldBounds.height - height);
		syncTileCoords();
	}
	
	override public function setPosition(X:Float = 0, Y:Float = 0):Void
	{
		super.setPosition(X, Y);
		syncTileCoords();
	}
	
	private function syncTileCoords():Void
	{
		var p:FlxPoint = FlxPoint.weak();
		gridRef.getGridCoords(x + offset.x + width/2, y + offset.y + height/2, p);
		tileRow = Std.int(p.x);
		tileCol = Std.int(p.y);
		p.putWeak();

	}
	public function isGrounded():Bool
	{
		return isTouching(FlxObject.FLOOR) || Math.abs(FlxG.worldBounds.height - (y + height)) < FlxMath.EPSILON;
	}
	
}