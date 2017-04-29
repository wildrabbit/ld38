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
import org.wildrabbit.toothdecay.GameInput;
import org.wildrabbit.toothdecay.Pickup;
import org.wildrabbit.toothdecay.PlayState;
import org.wildrabbit.toothdecay.world.Grid.TileType;

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
	
	private var initialStamina:Float = 90;
	public var stamina:Float = 0;
	private var staminaDepletionRate:Float = 3;
	
	private var drillSound: FlxSound;
	private var drillDelay:Float = 0.15;
	private var drillStrength:Float = 1;
	private var drillStart:Float = -1;
	
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
	
	public function new(parent:PlayState, grid:Grid, startRow:Int, startCol:Int) 
	{
		super(parent, grid);
		
		loadGraphic("assets/images/player.png", true,64, 64);
		animation.add("idle", [0, 1], 5,true);
		animation.add("move", [2,3], 5, true);
		animation.add("drill_down", [4,5],5,false);
		animation.add("drill_up", [7], 2, false);
		animation.add("drill_side", [6], 2, false);
		animation.add("die", [8], 2, true);
		animation.add("win", [9,10],5,true);
		
		animation.play("idle");
		animation.finishCallback = onAnimationFinished;
		
		setSize(44, 56);
		offset.set(11, 4);
		
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
			animation.play('die');
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
		if (won || !alive) { super.update(dt);  return; }
		
		
		var input:GameInput = parent.getMainInput();
		var drilling:Bool = input.drill;
		var now:Float = Date.now().getTime();
		var staminaCost:Float = 0;
		
		if (!drilling)
		{
			drillStart = -1;
		}
		
		// Read motion input
		var left:Bool = input.xValue < 0;
		if (left)
		{
			velocity.x = -speed;
		}
		var right:Bool = input.xValue > 0;
		if (right)
		{
			velocity.x = speed;
		}
		
		var drillAllowed:Bool = isGrounded() && drilling && (drillStart < 0 || (now - drillStart) * 0.001 > drillDelay);
		/*
		trace('Grounded: ${isGrounded()}');
		trace('Drilling: $drilling');
		trace('DrillStart: $drillStart');
		trace('Drill delay: $drillDelay');
		trace('Now: $now');
		trace('Drill allowed: $drillAllowed');
		*/
		
		if (drillAllowed)
		{	
			var anim:String = "";
			var rowDelta:Int = 0;
			var colDelta:Int = 0;
			facing = FlxObject.NONE;
			if (input.yValue < 0) { rowDelta = -1; anim = "drill_up";}
			else if (left) { colDelta = -1; anim = "drill_side"; facing = FlxObject.LEFT; }
			else if (right) { colDelta = 1; anim = "drill_side"; facing = FlxObject.RIGHT; }
			else { rowDelta = 1; anim = "drill_down";}
			
			var validCoords: Bool = (rowDelta != 0 || colDelta != 0) && !((colDelta > 0 && tileCol == gridRef.widthInTiles - 1) || (colDelta < 0 && tileCol == 0));
			if (validCoords)
			{
				if (!drillSound.playing && !FlxG.sound.muted)
				{
					drillSound.play(true);
				}
				staminaCost += gridRef.drillTile(tileRow + rowDelta, tileCol + colDelta, drillStrength);
				drillStart = now;
				if (anim != "")
				{
					animation.play(anim);				
				}
			}
		}
		
		var wasTouchingLeft:Bool = touchingLeft;
		touchingLeft = isTouching(FlxObject.LEFT);
		if (touchingLeft && left)
		{
			if (tileCol > 0 && tileRow > 0)
			{
				var tileID:Int = gridRef.getTile(tileCol - 1, tileRow - 1);
				if (tileID == TileType.Gap)
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
		if (touchingRight && right)
		{
			if (tileCol >= 0 && tileCol < gridRef.widthInTiles - 1 && tileRow > 0)
			{
				var tileID:Int = gridRef.getTile(tileCol + 1, tileRow - 1);
				//FlxG.log.add("right diag tile at $tileRow , $tileCol is $tileID");
				if (tileID == TileType.Gap)
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
		
		super.update(dt);		
		syncTileCoords();
		if (!drilling)
		{
			if (Math.abs(velocity.x) < FlxMath.EPSILON)
			{
				animation.play("idle");
			}
			else if (velocity.x > 0)
			{
				facing = FlxObject.RIGHT;
				animation.play("move");
			}
			else if (velocity.x < 0)
			{
				facing = FlxObject.LEFT;
				animation.play("move");
			}			
		}
		
		staminaCost += dt * staminaDepletionRate;
		
		stamina -= staminaCost;
		if (stamina <= 0)
		{
			stamina = 0;
			alive = false;
			deadSignal.dispatch(this);
		}
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