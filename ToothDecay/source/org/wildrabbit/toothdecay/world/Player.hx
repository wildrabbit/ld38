package org.wildrabbit.toothdecay.world;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKeyList;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxSound;
import flixel.util.FlxSignal;
import org.wildrabbit.toothdecay.Entity;
import org.wildrabbit.toothdecay.Pickup;

/**
 * ...
 * @author ith1ldin
 */
class Player extends Entity
{
	private var speed:Float = 200;
	
	private var holdLeft:Float = -1;
	private var holdRight:Float = -1;
	private var touchingLeft:Bool = false;
	private var touchingRight:Bool = false;
	
	private var initialStamina:Float = 100;
	public var stamina:Float = 0;
	private var staminaDepletionRate:Float = 2;
	
	private var drillSound: FlxSound;
	
	public var won:Bool = false;
	
	public function setGrid(leGrid:Grid, row:Int, col:Int):Void
	{
		if (gridRef != null)
		{
			gridRef.tileDropped.remove(onTileDropped);
		}
		gridRef = leGrid;
		gridRef.tileDropped.add(onTileDropped);
		
		setTile(row, col);
	}
	
	public function new(grid:Grid, startRow:Int, startCol:Int) 
	{
		super(grid);
		
		loadGraphic("assets/images/player.png", true,64, 64);
		animation.add("idle", [0]);
		animation.add("drill_down", [1],2,false);
		animation.add("drill_up", [2], 2, false);
		animation.add("drill_side", [3],2,false);
		animation.play("idle");
		animation.finishCallback = onAnimationFinished;
		
		setSize(38, 54);
		offset.set(13, 5);
		
		drag.set(1600, 0);
		maxVelocity.set(speed, 500);

		velocity.set();
		
		FlxG.watch.add(this, "tileRow");
		FlxG.watch.add(this, "tileCol");
		
		facing = FlxObject.NONE;
		setFacingFlip(FlxObject.LEFT, true, false);
		setFacingFlip(FlxObject.RIGHT, false, false);
		
		stamina = initialStamina;

		setTile(startRow, startCol);
		centerToTile();

		drillSound = new FlxSound();
		drillSound.loadEmbedded(AssetPaths.drill__wav);
		
		grid.tileDropped.add(onTileDropped);
	}
	
	public function onTileDropped(row:Int, col:Int):Void
	{
		if (row == tileRow && col == tileCol)
		{
			stamina = 0;
			alive = false;
			deadSignal.dispatch(this);
		}
	}
	
	public function onAnimationFinished(str:String):Void
	{
		if (str == "drill_down" || str == "drill_up" || str == "drill_side")
		{
			animation.play("idle");
		}
	}
	
	
	
	override public function update(dt:Float):Void
	{	
		if (won) return;
		
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
		
		if (isGrounded() && drilling)
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
				if (!drillSound.playing)
				{
					drillSound.play(true);
				}
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
			alive = false;
			deadSignal.dispatch(this);
		}
		
		super.update(dt);		
		syncTileCoords();
	}

	public function onPickup(obj1:Dynamic, obj2:Dynamic):Void
	{
		var pick:Pickup = cast obj2;
		if (pick != null && pick.alive)
		{
			if (pick.type == Pickup.SUGAR)
			{
				FlxG.sound.play(AssetPaths.sugar__wav);
				stamina = FlxMath.bound(stamina + pick.amount, 0, initialStamina);
				pick.onPicked();
			}
		}
	}

}