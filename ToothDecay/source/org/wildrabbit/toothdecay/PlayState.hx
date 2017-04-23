package org.wildrabbit.toothdecay;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import org.wildrabbit.toothdecay.world.Grid;
import org.wildrabbit.toothdecay.world.Player;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	var grid:Grid;
	var player:Player;
	
	var pickups:FlxTypedGroup<Pickup>;//
	var pickupList:Array<Pickup>;
	var specialTiles:FlxTypedGroup<FlxSprite>;
	
	var gameGroup:FlxGroup;
	var hudGroup:FlxGroup;
	
	var left:FlxSprite;	
	var right:FlxSprite;
	
	var gridCamera:FlxCamera;
	var hudCamera:FlxCamera;
	
	var stamina:FlxText;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create(); //
		bgColor = Reg.backgroundColour;//0xf3e9d5;
		gameGroup = new FlxGroup();
		add(gameGroup);
		grid = new Grid();
		grid.setPosition(0, 0);
		grid.init();
		FlxG.worldBounds.set(0, 0, grid.width, grid.height);
		gameGroup.add(grid);
		
		player = new Player(grid, 0, 4);
		player.deadSignal.addOnce(onPlayerDied);
		
		pickups = new FlxTypedGroup<Pickup>();
		pickupList = new Array<Pickup>();
		var pick:Pickup = new Pickup(grid, 10, 2);
		pick.deadSignal.add(onPickupTaken);
		pickups.add(pick);
		pickupList.push(pick);
		gameGroup.add(pickups);
		
		specialTiles = new FlxTypedGroup<FlxSprite>();
		gameGroup.add(specialTiles);
		gameGroup.add(player);
		
		grid.root = specialTiles;
	
		
		hudGroup = new FlxGroup();
		add(hudGroup);
		left = new FlxSprite(0, 0);
		left.makeGraphic(64, Std.int(grid.height), FlxColor.BLACK);
		right = new FlxSprite(64 + grid.width, 0);
		right.makeGraphic(128, Std.int(grid.height), FlxColor.BLACK);
		
		stamina = new FlxText(660, 10, 140, '${Std.int(player.stamina)}', 24);
		stamina.color = FlxColor.WHITE;
		
		hudGroup.add(left);
		hudGroup.add(right);
		hudGroup.add(stamina);

		gridCamera = new FlxCamera(64, 0, Std.int(grid.width), FlxG.height, 1);
		gridCamera.bgColor = bgColor;
		gridCamera.follow(player, FlxCameraFollowStyle.LOCKON, 0.15);
		gridCamera.setScrollBounds(0, grid.width, 0, grid.height);
		hudCamera = new FlxCamera(0,0,FlxG.width, FlxG.height,1);
		hudCamera.bgColor = bgColor;
		
		
		FlxCamera.defaultCameras = null;
		FlxG.cameras.reset(hudCamera);
		FlxG.cameras.add(gridCamera);
				
		setGroupCamera(gameGroup, gridCamera);
		setGroupCamera(hudGroup, hudCamera);
		
		FlxG.watch.add(gridCamera, 'followLerp');
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		player = null;
		grid = null;
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

		FlxG.collide(grid, pickups);
		FlxG.collide(grid, player);
		FlxG.overlap(player, pickups, player.onPickup);
		if (grid.state == Grid.STATE_NONE)
		{
			grid.clusterfuck(player.tileRow, player.tileCol, pickupList);			
		}
		
		player.keepBounds();
		
		if (!player.won && player.tileRow == grid.heightInTiles - 1 && player.isGrounded())
		{
			FlxG.sound.play(AssetPaths.won__wav);
			player.won = true;
		}
		
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
		group.forEachExists(func);
	}
	
	private function onPlayerDied(e:Entity):Void
	{
		var reset = function (t:FlxTween):Void
		{
			FlxG.sound.play(AssetPaths.dead__wav);
			new FlxTimer().start(3, function(t:FlxTimer):Void {  FlxG.resetGame(); } );
		}
		FlxTween.tween(e, { "alpha":0 }, 0.5, { type:FlxTween.ONESHOT, onComplete:reset, ease:FlxEase.sineInOut } );
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
}