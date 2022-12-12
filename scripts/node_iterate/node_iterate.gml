enum ITERATION_STATUS {
	not_ready,
	loop,
	complete,
}

function Node_create_Iterate(_x, _y) {
	var node = new Node_Iterate(_x, _y);
	ds_list_add(PANEL_GRAPH.nodes_list, node);
	return node;
}

function Node_Iterate(_x, _y) : Node_Collection(_x, _y) constructor {
	name = "Loop";
	color = COLORS.node_blend_loop;
	icon  = THEME.loop;
	
	iterated = 0;
	
	inputs[| 0] = nodeValue( 0, "Repeat", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1 );
	
	custom_input_index = 1;
	loop_start_time = 0;
	
	static postSetRenderStatus = function(result) {
		if(rendered) return;
		
		iterated = 0;
		loop_start_time = get_timer();
	}
	
	static iterationStatus = function() {
		var iter = true;
		for( var i = 0; i < ds_list_size(outputs); i++ ) {
			var _out = outputs[| i].node;
			iter &= _out.rendered;
		}
		
		if(iter) {
			if(++iterated == inputs[| 0].getValue()) {
				render_time = get_timer() - loop_start_time;
				return ITERATION_STATUS.complete;
			} else if(iterated > inputs[| 0].getValue())
				return ITERATION_STATUS.complete;
			
			resetRenderStatus();
			return ITERATION_STATUS.loop;
		}
		
		return ITERATION_STATUS.not_ready;
	}
}