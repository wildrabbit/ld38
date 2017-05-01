package org.wildrabbit.toothdecay.util;

import haxe.ds.Vector;
/**
 * ...
 * @author ith1ldin
 */
class DisjointSet
{
	private var parents:Vector<Int>;
	private var ranks:Vector<Int>;
	private var sets:Int;
	
	public function new(numElems:Int) 
	{
		parents = new Vector<Int>(numElems);
		ranks = new Vector<Int>(numElems);
		for (i in 0...numElems)
		{
			parents[i] = i;
			ranks[i] = 0;
		}
		sets = 0;
	}
	
	public function find(x:Int):Int	
	{
		if(parents[x] != x)
            return find(parents[x]);
        return parents[x];
	}
	
	public function union (x:Int, y:Int):Void
	{
		var xRoot:Int = find(x);
		var yRoot:Int = find(y);
		if (xRoot == yRoot) return;
		if (ranks[xRoot]< ranks[yRoot])
		{
			parents[xRoot] = yRoot;
		}
		else if (ranks[xRoot] > ranks[yRoot])
		{
			parents[yRoot] = xRoot;
		}
		else 
		{
			parents[yRoot] = xRoot;
			ranks[xRoot] = ranks[xRoot] + 1;
		}
	}
	
}