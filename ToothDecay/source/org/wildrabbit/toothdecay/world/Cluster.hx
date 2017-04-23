package org.wildrabbit.toothdecay.world;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;

/**
 * ...
 * @author ith1ldin
 */
class Cluster
{
	public var label:Int;
	public var type:Int = Grid.TILE_GAP;
	public var indexes:Array<Int> = new Array<Int>();
	public var connected:Bool = false;
	
	public function new() 
	{
	}
	
	public function toString():String
	{
		return 'Label: $label, Type: $type, Indexes: $indexes, Connected: $connected';
	}

 }
