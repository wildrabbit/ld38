package org.wildrabbit.toothdecay;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import org.wildrabbit.toothdecay.world.Grid;
import org.wildrabbit.toothdecay.world.Player;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	var grid:Grid;
	var player:Player;
	
	var gameGroup:FlxGroup;
	var hudGroup:FlxGroup;
	
	var left:FlxSprite;	
	var right:FlxSprite;
	
	var gridCamera:FlxCamera;
	var hudCamera:FlxCamera;
	
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
		
		player = new Player(grid);
		gameGroup.add(player);
		player.setTile(0,4);
		
		hudGroup = new FlxGroup();
		add(hudGroup);
		left = new FlxSprite(0, 0);
		left.makeGraphic(64, Std.int(grid.height), FlxColor.BLACK);
		right = new FlxSprite(64 + grid.width, 0);
		right.makeGraphic(128, Std.int(grid.height), FlxColor.BLACK);
		
		hudGroup.add(left);
		hudGroup.add(right);
		
		gridCamera = new FlxCamera(64, 0, Std.int(grid.width), FlxG.height, 1);
		gridCamera.bgColor = bgColor;
		gridCamera.follow(player, FlxCameraFollowStyle.LOCKON, 5);
		gridCamera.setScrollBounds(0, grid.width, 0, grid.height);
		hudCamera = new FlxCamera(0,0,FlxG.width, FlxG.height,1);
		hudCamera.bgColor = bgColor;
		
		
		FlxCamera.defaultCameras = null;
		FlxG.cameras.reset(hudCamera);
		FlxG.cameras.add(gridCamera);
				
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
		grid = null;
		left = null;
		right = null;
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(dt:Float):Void
	{
		super.update(dt);
		
		if (FlxG.keys.pressed.ESCAPE)
		{
			FlxG.switchState(new MenuState());
		}

		FlxG.collide(grid, player);
		player.keepBounds();
	}
	
	private function setGroupCamera(group:FlxGroup, cam:FlxCamera):Void 
	{
		var func = function(obj:FlxBasic):Void
		{
			obj.camera = cam;
		};
		group.forEachExists(func);
	}
}