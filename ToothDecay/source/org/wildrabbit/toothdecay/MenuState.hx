package org.wildrabbit.toothdecay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

/**
 * A FlxState which can be used for the game's menu.
 */
class MenuState extends FlxState
{
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		bgColor = Reg.backgroundColour;
		var bg = new FlxSprite(0, 0);
		bg.loadGraphic(AssetPaths.mainscreen__png);
		add(bg);
		var txt = new FlxText(0, 600 - 24, 320, "Press any key to start", 12);
		add(txt);
		FlxG.camera.fill(bgColor, false);
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(dt:Float):Void
	{
		super.update(dt);
		if (FlxG.keys.pressed.ANY)
		{
			FlxG.switchState(new PlayState());
		}
	}
}