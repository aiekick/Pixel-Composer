function Node_Collection(_x,  _y) : Node(_x,  _y) constructor {
	nodes = ds_list_create();
	
	function add(_node) {
		ds_list_add(nodes, _node);
		var list = _node.group == -1? PANEL_GRAPH.nodes_list : _node.group.nodes;
		var _pos = ds_list_find_index(list, _node);
		ds_list_delete(list, _pos);
		
		recordAction(ACTION_TYPE.group_added, self, _node);
		_node.group = self;
	}
	
	function remove(_node) {
		var _pos = ds_list_find_index(nodes, _node);
		ds_list_delete(nodes, _pos);
		var list = group == -1? PANEL_GRAPH.nodes_list : group.nodes;
		ds_list_add(list, _node);
		
		recordAction(ACTION_TYPE.group_removed, self, _node);
		_node.group = group;
	}
	
	function stepBegin() {
		for(var i = 0; i < ds_list_size(nodes); i++) {
			nodes[| i].stepBegin();
		}
	}
	
	static step = function() {
		render_time = 0;
		for(var i = 0; i < ds_list_size(nodes); i++) {
			nodes[| i].step();
			render_time += nodes[| i].render_time;
		}
		
		if(PANEL_GRAPH.node_focus == self && FOCUS == PANEL_GRAPH.panel && DOUBLE_CLICK) {
			PANEL_GRAPH.addContext(self);
			DOUBLE_CLICK = false;
		}
	}
	
	static preConnect = function() {
		sortIO();
		deserialize(keyframe_scale);
	}
	
	static sortIO = function() {
		var siz = ds_list_size(inputs);
		var ar = ds_priority_create();
		
		for( var i = 0; i < siz; i++ ) {
			var _in = inputs[| i];
			var _or = _in.from.inputs[| 5].getValue();
			
			ds_priority_add(ar, _in, _or);
		}
		
		ds_list_clear(inputs);
		for( var i = 0; i < siz; i++ ) {
			var _jin = ds_priority_delete_min(ar);
			_jin.index = i;
			ds_list_add(inputs, _jin);
		}
		
		ds_priority_destroy(ar);
		
		var siz = ds_list_size(outputs);
		var ar = ds_priority_create();
		
		for( var i = 0; i < siz; i++ ) {
			var _out = outputs[| i];
			var _or = _out.from.inputs[| 1].getValue();
			
			ds_priority_add(ar, _out, _or);
		}
		
		ds_list_clear(outputs);
		for( var i = 0; i < siz; i++ ) {
			var _jout = ds_priority_delete_min(ar);
			_jout.index = i;
			ds_list_add(outputs, _jout);
		}
		
		ds_priority_destroy(ar);
	}
}