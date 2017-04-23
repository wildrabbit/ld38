package org.wildrabbit.toothdecay;

import flixel.util.FlxColor;
import flixel.util.FlxSave;
import haxe.Json;
import haxe.ds.IntMap;

import openfl.Assets;
/**
 * Handy, pre-built Registry class that can be used to store
 * references to objects and other things for quick-access. Feel
 * free to simply ignore it or change it in any way you like.
 */

 typedef IntVec2 =
{
	var col:Int;
	var row:Int;
}
typedef PickupJson = 
{
	var type:Int;
	var amount:Int;
	var startPos:IntVec2;
}

typedef WeightEntry =
{
	var tile:Int;
	var value:Float;
}

 typedef LevelJson = 
 {
	var id:Int;
	var generated:Bool;
	var playerStart:IntVec2;
	var base:Array<Int>;
	var pickupList:Array<PickupJson>;
	var width:Int;
	var height:Int;
	@:optional var minStamina:Int;
	@:optional var maxStamina:Int;
	@:optional var generatePickups:Bool;
	@:optional var blockDensities:Array<WeightEntry>;
 }

 typedef LevelList =
 {
	 var levels:Array<LevelJson>;
 }

 
class Reg
{
	public static function lastLevel():Bool 
	{
		return Reg.level == levelOrdering.length - 1;
	}
	public static var backgroundColour:FlxColor = FlxColor.fromRGB(0xf3,0xe9,0xd5);
	/**
	 * Generic levels Array that can be used for cross-state stuff.
	 * Example usage: Storing the levels of a platformer.
	 */
	public static var levels:Map<Int, LevelJson> = new Map<Int,LevelJson>();
	
	/** Level order */
	public static var levelOrdering:Array<Int> = [];
	/**
	 * Generic level variable that can be used for cross-state stuff.
	 * Example usage: Storing the current level number.
	 */
	public static var level:Int = 0;
	/**
	 * Generic scores Array that can be used for cross-state stuff.
	 * Example usage: Storing the scores for level.
	 */
	public static var scores:Array<Dynamic> = [];
	/**
	 * Generic score variable that can be used for cross-state stuff.
	 * Example usage: Storing the current score.
	 */
	public static var score:Int = 0;
	/**
	 * Generic bucket for storing different FlxSaves.
	 * Especially useful for setting up multiple save slots.
	 */
	public static var saves:Array<FlxSave> = [];
	
	public static function loadLevels():Void
	{
		var levelFile:String = Assets.getText("assets/data/levels.json");
		var levelList:LevelList = Json.parse(levelFile);
		var levelOrdering:Array<Int> = new Array<Int>();
		for (leveljson in levelList.levels)
		{
			levels.set(leveljson.id, leveljson);
			levelOrdering.push(leveljson.id);
		}
	}
	
	public static function getLevel(id:Int):LevelJson
	{
		if (levels.exists(id))
		{
			level = levelOrdering.indexOf(id);
			return levels[id];
		}
		return null;
	}
}