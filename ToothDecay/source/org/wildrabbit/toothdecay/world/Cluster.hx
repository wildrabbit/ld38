package org.wildrabbit.toothdecay.world;

/**
 * ...
 * @author ith1ldin
 */
class Cluster
{
	public var label:Int;
	public var type:Int = Grid.TILE_GAP;
	public var indexes:List<Int> = new List<Int>();
	public var connected:Bool = false;
	
	public function new() 
	{
	}
	
	public function toString():String
	{
		return 'Label: $label, Type: $type, Indexes: $indexes, Connected: $connected';
	}
 }