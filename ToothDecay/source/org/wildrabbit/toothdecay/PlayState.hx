package org.wildrabbit.toothdecay;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import haxe.ds.Vector;
import org.wildrabbit.toothdecay.Reg.IntVec2;
import org.wildrabbit.toothdecay.Reg.LevelJson;
import org.wildrabbit.toothdecay.Reg.PickupJson;
import org.wildrabbit.toothdecay.world.Grid;
import org.wildrabbit.toothdecay.world.Player;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	
	private static inline var BORDER_WIDTH:Float = 112;
	var oldGrid:Grid;
	var currentGrid:Grid;
	var gridIdx:Int;
	var endLevelSprite:Grid;
	
	var needsNewGrid:Bool = false;
	var purgePrevious:Bool = false;
	
	@:allow(org.wildrabbit.toothdecay.world.Grid)
	var player:Player;
	
	var pickups:FlxTypedGroup<Pickup>;//
	@:allow(org.wildrabbit.toothdecay.world.Grid)
	var pickupList:Array<Pickup>;
	var specialTiles:FlxTypedGroup<FlxSprite>;
	
	var gameGroup:FlxGroup;
	var hudGroup:FlxGroup;
	
	var left:FlxSprite;	
	var right:FlxSprite;
	
	var gridCamera:FlxCamera;
	var hudCamera:FlxCamera;
	
	var stamina:FlxText;
	
	var gameRandom:FlxRandom = new FlxRandom();
	
	var currentLevel:LevelJson;
	private static inline var defW:Int = 9;
	private static inline var defH:Int = 20;
	private static var defArray:Array<Int> =[
			0, 0, 0, 0, 0, 0, 0, 0,0,
			1, 4, 0, 0, 2, 2, 1, 2,3,
			5, 2, 2, 3, 4, 1, 0, 4,3,
			1, 3, 1, 3, 2, 2, 1, 4,3,
			4, 2, 3, 3, 4, 1, 0, 4,1,
			2, 2, 2, 1, 5, 4, 2, 3,2,
			0, 0, 5, 0, 4, 1, 0, 4,2,
			1, 2, 2, 3, 4, 1, 0, 0,0,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 4, 0, 2, 4, 1, 0, 4,5,
			3, 4, 0, 1, 2, 2, 1, 2,3,
			5, 2, 2, 3, 4, 1, 0, 4,3,
			1, 3, 1, 3, 2, 2, 1, 4,3,
			4, 2, 3, 3, 4, 1, 0, 4,1,
			2, 2, 2, 1, 5, 4, 2, 3,2,
			0, 0, 5, 0, 4, 1, 0, 4,2,
			1, 2, 2, 3, 4, 1, 0, 0,0,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 2, 2, 3, 4, 1, 0, 4,5,
			1, 2, 2, 3, 4, 1, 0, 4,5
	];
	private static var defPlayer:IntVec2 = { col:4, row:0 };
	private static var defPickups:Array<PickupJson> = [
		{type:Pickup.SUGAR, amount:10, startPos: { col:2, row:10 }}
	];
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create(); //
		
		var levelArray:Array<Int> = defArray;
		var pickupData:Array<PickupJson> = defPickups;
		var width: Int = defW;
		var height:Int = defH;
		var playerStart:IntVec2 = defPlayer;
		
		currentLevel = Reg.getLevel(0);
		if (currentLevel != null)
		{
			width = currentLevel.width;
			height = currentLevel.height;
			if (currentLevel.generated)
			{
				levelArray = generateTiles(currentLevel);
				pickupData = generatePickups(currentLevel, levelArray);
			}
			else
			{
				levelArray = currentLevel.base;
				pickupData = currentLevel.pickupList;
			}
		}
		
		
		bgColor = Reg.backgroundColour;//0xf3e9d5;
		gameGroup = new FlxGroup();
		add(gameGroup);
		currentGrid = new Grid(this);
		currentGrid.setPosition(0, 0);
		
		
		currentGrid.init(levelArray, width, height);
		FlxG.worldBounds.set(0, 0, currentGrid.width, currentGrid.height);
		gameGroup.add(currentGrid);
		
		player = new Player(currentGrid, playerStart.row, playerStart.col);
		player.deadSignal.addOnce(onPlayerDied);
		player.reachedBottom.addOnce(onReachedBottom);
		
		pickups = new FlxTypedGroup<Pickup>();
		pickupList = new Array<Pickup>();
		for (pickInfo in pickupData)
		{
			var pick:Pickup = new Pickup(currentGrid, pickInfo.type, pickInfo.amount, pickInfo.startPos.row, pickInfo.startPos.col);
			pick.deadSignal.add(onPickupTaken);
			pickups.add(pick);
			pickupList.push(pick);			
		}
		gameGroup.add(pickups);
		
		specialTiles = new FlxTypedGroup<FlxSprite>();
		gameGroup.add(specialTiles);
		gameGroup.add(player);
		
		currentGrid.root = specialTiles;
	
		
		hudGroup = new FlxGroup();
		add(hudGroup);
		left = new FlxSprite(0, 0);
		left.loadGraphic(AssetPaths.border__png);
		//left.makeGraphic(BORDER_WIDTH, Std.int(currentGrid.height), FlxColor.BLACK);
		var l2 = new FlxSprite(0, 0);
		l2.loadGraphic(AssetPaths.border2__png);
		right = new FlxSprite(FlxG.width - left.frameWidth, 0);
		right.loadGraphic(AssetPaths.border__png);
		right.setFacingFlip(FlxObject.RIGHT, true, false);
		right.facing = FlxObject.RIGHT;		
		var r2 = new FlxSprite(FlxG.width - l2.frameWidth, 0);
		r2.loadGraphic(AssetPaths.border2__png);
		r2.setFacingFlip(FlxObject.RIGHT, true, false);
		r2.facing = FlxObject.RIGHT;		
		//right.makeGraphic(BORDER_WIDTH, Std.int(currentGrid.height), FlxColor.BLACK);
		
		stamina = new FlxText(BORDER_WIDTH + currentGrid.width, 10, 140, '${Std.int(player.stamina)}', 24);
		stamina.color = FlxColor.WHITE;
		
		hudGroup.add(l2);
		hudGroup.add(left);
		hudGroup.add(r2);
		hudGroup.add(right);
		hudGroup.add(stamina);

		gridCamera = new FlxCamera(BORDER_WIDTH, 0, Std.int(currentGrid.width), FlxG.height, 1);
		gridCamera.bgColor = bgColor;
		gridCamera.follow(player, FlxCameraFollowStyle.LOCKON, 0.15);
		gridCamera.setScrollBounds(0, currentGrid.width, 0, currentGrid.height);
		hudCamera = new FlxCamera(0,0,FlxG.width, FlxG.height,1);
		hudCamera.bgColor = FlxColor.TRANSPARENT;
		
		
		//FlxCamera.defaultCameras = null;
		FlxG.cameras.reset(gridCamera);
		FlxG.cameras.add(hudCamera);
				
		setGroupCamera(gameGroup, gridCamera);
		setGroupCamera(hudGroup, hudCamera);
		
		
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		player = null;
		currentGrid = null;
		left = null;
		right = null;
		
		pickups = null;
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(dt:Float):Void
	{
		super.update(dt);
		
		if (FlxG.keys.pressed.ESCAPE)
		{
			FlxG.resetState();
		}

		
		FlxG.collide(currentGrid, pickups);
		FlxG.collide(currentGrid, player);
		FlxG.overlap(player, pickups, player.onPickup);
		
		player.keepBounds();
		
		var playerAtBottom:Bool = player.tileRow == currentGrid.heightInTiles - 1 && player.isGrounded();
		var lastLevel:Bool = Reg.lastLevel();
		
		if (player.won) return;
		
		if (playerAtBottom)
		{
			if (lastLevel)
			{
				FlxG.sound.play(AssetPaths.won__wav);
				player.won = true;
				player.centerToTile();
				player.animation.play("win");
			}
/*			else if (shouldSwapGrid()) // Drilled past the transition one
			{
				
			}*/
		}
		else if (shouldGetTransitionGrid())
		{
			createEndLevelGrid();			
			// create next grid
			//FlxG.worldBounds.height += endLevelSprite.height;
		}
		
		if (oldGrid != null) 
			purgeOldGrid();
		

		
		if (player.alive)
		{
			if (player.won)
				stamina.text = "WON! :D";
			else 
				stamina.text = '${Std.int(player.stamina)}';
		}
		else {
			stamina.text = "DEAD! >_<";
		}			
	}
	
	private function setGroupCamera(group:FlxGroup, cam:FlxCamera):Void 
	{
		var func = function(obj:FlxBasic):Void
		{
			obj.camera = cam;
		};
		group.forEachExists(func, true);
	}
	
	private function onPlayerDied(e:Entity):Void
	{
		player.animation.play("die");
		player.centerToTile();
		FlxG.sound.play(AssetPaths.dead__wav);
			
		/*var reset = function (t:FlxTween):Void
		{
			//new FlxTimer().start(3, function(t:FlxTimer):Void {  FlxG.resetGame(); } );
		}
		FlxTween.tween(e, { "alpha":0 }, 0.5, { type:FlxTween.ONESHOT, onComplete:reset, ease:FlxEase.sineInOut } );*/
	}
	
	private function onPickupTaken(e:Entity):Void
	{
		var removePickup = function (t:FlxTween):Void
		{
			pickups.remove(cast e);
			pickupList.remove(cast e);
			e.destroy();
		}
		FlxTween.tween(e, { "alpha":0 }, 0.2, { type:FlxTween.ONESHOT, onComplete:removePickup} );
	}
	
	private function loadLevel(levelID:Int):LevelJson
	{
		return Reg.getLevel(levelID);
	}
	private function generateTiles(levelData:LevelJson):Array<Int>
	{
		var numTiles = levelData.width * levelData.height;
		
		var grid:Array<Int> = new Array<Int>();
		if (levelData.base != null && levelData.base.length > 0)
		{
			grid = levelData.base.slice(0, levelData.base.length);
		}
		else
		{
			for (i in 0...numTiles)
			{
				grid.push( -1);
			}
		}
		
		var objs:Array<Int> = new Array<Int>();
		var weights:Array<Float> = new Array<Float>();
		for (pair in levelData.blockDensities)
		{
			objs.push(pair.tile);
			weights.push(pair.value);
		}
		
		for (i in 0...numTiles)
		{
			if (grid[i] != -1) continue;

			var tileID:Int = gameRandom.getObject(objs, weights);
			if (i == levelData.width * levelData.playerStart.row + levelData.playerStart.col)
			{
				tileID = Grid.TILE_GAP;
			}
			grid[i] = tileID;
		}

		return grid;
	}
	
	private function generatePickups(levelData:LevelJson, grid:Array<Int>):Array<PickupJson>
	{
		var array:Array<PickupJson> = defPickups;
		if (levelData.generatePickups)
		{
			array = new Array<PickupJson>();
			var rowIdx:Int = gameRandom.int(levelData.minStamina, levelData.maxStamina);
			while (rowIdx < levelData.height)
			{
				var candidateCols:Array<Int> = new Array<Int>();
				for (colIdx in 0...levelData.width)
				{
					var idx:Int = rowIdx * levelData.width + colIdx;
					if (grid[idx] == Grid.TILE_GAP)
					{
						candidateCols.push(colIdx);
					}
				}
				var chosenCol:Int = -1;
				if (candidateCols.length > 0)
				{
					chosenCol = candidateCols[gameRandom.int(0, candidateCols.length - 1)];
				}
				else
				{
					chosenCol = gameRandom.int(0, levelData.width - 1);
				}
				array.push({
					type:Pickup.SUGAR,
					amount:10,
					startPos:{row:rowIdx, col:chosenCol}
				});
			
				rowIdx += gameRandom.int(levelData.minStamina, levelData.maxStamina);
			}
			
		}
		else if (levelData.pickupList != null && levelData.pickupList.length > 0)
		{
			array = levelData.pickupList;
		}
		
		if (array != null && array.length > 0)
		{
			for (pickupItem in array)
			{
				var idx:Int = pickupItem.startPos.row * levelData.width + pickupItem.startPos.col;
				grid[idx] = Grid.TILE_GAP;
			}
		}
		return array;
	}
	
	private function shouldGetTransitionGrid():Bool
	{
		if (Reg.lastLevel()) return false;
		if (endLevelSprite != null) return false;
		
		var screenTiles:Int = Std.int(gridCamera.height / currentGrid.tileHeight);
		return player.tileRow >= currentGrid.heightInTiles - screenTiles;
	}
	
	private function createEndLevelGrid():Void 
	{
		endLevelSprite = new Grid(this);
		var tiles:Vector<Int> = new Vector<Int>(currentGrid.widthInTiles * 6);
		for (i in 0...tiles.length)
		{
			if (i < currentGrid.widthInTiles)
				tiles[i] = Grid.TILE_GAP;
			else
				tiles[i] = Grid.TILE_ENDLEVEL;
		}
		
		endLevelSprite.init(tiles.toArray(), currentGrid.widthInTiles, 6);
		endLevelSprite.setPosition(currentGrid.x, currentGrid.height - currentGrid.tileHeight);
		gameGroup.add(endLevelSprite);
	}
	
	private function onReachedBottom(e:Entity):Void
	{
		if (Reg.lastLevel()) return;
		
		if (e != player) return;
		oldGrid = currentGrid;
		currentGrid = endLevelSprite;
		endLevelSprite = null;		
		player.setGrid(currentGrid, 0, player.tileCol);
		FlxG.worldBounds.set(currentGrid.x, currentGrid.y, currentGrid.width, currentGrid.height);
	}
	private function purgeOldGrid():Void
	{
		if (gridCamera.scroll.y > oldGrid.y + oldGrid.height)
		{
			gameGroup.remove(oldGrid);
			oldGrid.destroy();
			oldGrid = null;
		}
	}
}