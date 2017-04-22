package org.wildrabbit.toothdecay.world;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKeyList;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSignal;

/**
 * ...
 * @author ith1ldin
 */
class Player extends FlxSprite
{
	private var speed:Float = 200;
	private var fallSpeed:Float = 500;
	private var gravity:Float = 500;
	
	private var gridRef:Grid = null;
	
	private var tileCol:Int = 0;
	private var tileRow:Int = 0;
	
	private var holdLeft:Float = -1;
	private var holdRight:Float = -1;
	private var touchingLeft:Bool = false;
	private var touchingRight:Bool = false;
	
	private var initialStamina:Float = 100;
	private var stamina:Float = 0;
	private var staminaDepletionRate:Float = 2;
	
	public var deadSignal: FlxSignal;
	
	public function new(grid:Grid) 
	{
		super(0, 0);
		gridRef = grid;
		
		loadGraphic("assets/images/player.png", true,64, 64);
		animation.add("idle", [0]);
		animation.add("drill_down", [1],2,false);
		animation.add("drill_up", [2], 2, false);
		animation.add("drill_side", [3],2,false);
		animation.play("idle");
		animation.finishCallback = onAnimationFinished;
		
		//moves = false;
		
		setSize(38, 54);
		offset.set(13, 5);
		
		drag.set(1600, 0);
		maxVelocity.set(speed, 500);
		acceleration.y = 800;
		velocity.set();
		
		FlxG.watch.add(this, "tileRow");
		FlxG.watch.add(this, "tileCol");
		
		facing = FlxObject.NONE;
		setFacingFlip(FlxObject.LEFT, true, false);
		setFacingFlip(FlxObject.RIGHT, false, false);
		
		stamina = initialStamina;
		deadSignal = new FlxSignal();
	}
	
	public function onAnimationFinished(str:String):Void
	{
		if (str == "drill_down" || str == "drill_up" || str == "drill_side")
		{
			animation.play("idle");
		}
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
	
	override public function update(dt:Float):Void
	{	
		var drilling:Bool = FlxG.keys.pressed.SPACE;
		var left:Bool = FlxG.keys.pressed.LEFT;
		if (left && !drilling)
		{
			velocity.x = -speed;
		}
		var right:Bool = FlxG.keys.pressed.RIGHT;
		if (right && ! drilling)
		{
			velocity.x = speed;
		}
		
		var grounded:Bool = isTouching(FlxObject.FLOOR) || Math.abs(FlxG.worldBounds.height - (y + height)) < FlxMath.EPSILON;
		if (grounded && drilling)
		{	
			var rowDelta:Int = 0;
			var colDelta:Int = 0;
			var anim:String = "idle";
			facing = FlxObject.NONE;
			if (FlxG.keys.pressed.UP) { rowDelta = -1; anim = "drill_up";}
			else if (FlxG.keys.pressed.LEFT) { colDelta = -1; anim = "drill_side"; facing = FlxObject.LEFT; }
			else if (FlxG.keys.pressed.RIGHT) { colDelta = 1; anim = "drill_side"; facing = FlxObject.RIGHT; }
			else { rowDelta = 1; anim = "drill_down";}
			
			if (rowDelta != 0 || colDelta != 0)
			{
				gridRef.drillTile(tileRow + rowDelta, tileCol + colDelta);
				animation.play(anim);
			}
		}
		
		var now:Float = Date.now().getTime();
		var wasTouchingLeft:Bool = touchingLeft;
		touchingLeft = isTouching(FlxObject.LEFT);
		if (touchingLeft && FlxG.keys.pressed.LEFT)
		{
			if (tileCol > 0 && tileRow > 0)
			{
				var tileID:Int = gridRef.getTile(tileCol - 1, tileRow - 1);
				if (tileID == Grid.TILE_GAP)
				{
					if (!wasTouchingLeft)
					{
						holdLeft = now;
					}
					else if (holdLeft >= 0 && now - holdLeft > 500)
					{
						FlxG.log.add("Climb left!");
						setTile(tileRow - 1, tileCol - 1, true);
						holdLeft = -1;						
					}
					
				}
			}					
		}
		else if (holdLeft >= 0)
		{
			holdLeft = -1;
		}
		
		
		var wasTouchingRight:Bool = touchingRight;
		touchingRight = isTouching(FlxObject.RIGHT);
		if (touchingRight && FlxG.keys.pressed.RIGHT)
		{
			if (tileCol >= 0 && tileCol < gridRef.widthInTiles - 1 && tileRow > 0)
			{
				var tileID:Int = gridRef.getTile(tileCol + 1, tileRow - 1);
				//FlxG.log.add("right diag tile at $tileRow , $tileCol is $tileID");
				if (tileID == Grid.TILE_GAP)
				{
					if (!wasTouchingRight)
					{
						holdRight = now;
					//	FlxG.log.add("Hold right started at" + holdRight / 1000);
					}
					else if (holdRight >= 0 && now - holdRight > 500)
					{
				//		FlxG.log.add("Climb right!");
						setTile(tileRow - 1, tileCol + 1);
						holdRight = -1;											
					}					
				}
			}					
		}
		else if (holdRight >= 0)
		{
			holdRight = -1;
			//FlxG.log.add("Hold right reset");
		}
		
		//x += (velocity.x -drag.x)* dt;
		//position.y += (velocity.y - drag.y) * dt;
		
		var spentStamina:Float = dt * staminaDepletionRate;
		stamina -= spentStamina;
		if (stamina <= 0)
		{
			stamina = 0;
			deadSignal.dispatch();
		}
		
		super.update(dt);		
		syncTileCoords();
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
}