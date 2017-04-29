package org.wildrabbit.toothdecay;
import flixel.FlxG;
import flixel.input.FlxPointer;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;

/**
 * ...
 * @author ith1ldin
 */
class GameInput
{
	public var toggleGodMode:Bool = false;
	
	public var xValue:Int = 0;
	public var yValue:Int = 0;
	public var drill:Bool = false;

	public var togglePause:Bool = false;
	public var reset:Bool = false;
	public var any:Bool = false;
	
	public function new():Void { }

	public function clear():Void
	{
		toggleGodMode = false;
		xValue = yValue = 0;
		drill = false;
		togglePause = false;
		reset = false;
		any = false;
	}
	
	public function gatherInputs():Void
	{
		toggleGodMode = FlxG.keys.justReleased.F1;
	}
}

class KeyMouseInput extends GameInput
{	
	public function new()
	{
		super();
	}
	
	override public function gatherInputs():Void
	{
		super.gatherInputs();
		xValue = yValue = 0;
		drill = togglePause = reset = false;

		togglePause = FlxG.keys.justReleased.P;
		reset = FlxG.keys.justReleased.ESCAPE;
		if (FlxG.keys.pressed.LEFT)
		{
			xValue = -1;
		}
		else if (FlxG.keys.pressed.RIGHT)
		{
			xValue = 1;
		}
		
		if (FlxG.keys.pressed.DOWN)
		{
			yValue = 1;
		}
		else if (FlxG.keys.pressed.UP)
		{
			yValue = -1;
		}

		drill = FlxG.keys.pressed.SPACE;
		any = FlxG.keys.pressed.ANY || FlxG.mouse.pressed;
	}
}

class GamepadInput extends GameInput
{
	public function new()
	{
		super();
	}
	override public function gatherInputs():Void
	{	
		super.gatherInputs();
		xValue = yValue = 0;
		drill = togglePause = reset = false;		
		
		#if !FLX_NO_GAMEPAD		
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			xValue = Std.int(gamepad.analog.value.LEFT_STICK_X);
			yValue = Std.int(gamepad.analog.value.LEFT_STICK_Y);
			
			drill = gamepad.pressed.A;
			togglePause = gamepad.justPressed.START;
			reset = gamepad.justPressed.BACK;
			any = gamepad.pressed.ANY;
		}		
		#end
	}
}