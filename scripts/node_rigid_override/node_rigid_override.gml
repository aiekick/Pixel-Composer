function Node_Rigid_Override(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Rigidbody Override";
	color = COLORS.node_blend_simulation;
	icon  = THEME.rigidSim;
	previewable = false;
	node_draw_icon = s_node_rigid_override;
	
	w = 96;
	h = 80;
	min_h = h;
	
	inputs[| 0] = nodeValue("Object", self, JUNCTION_CONNECT.input, VALUE_TYPE.rigid, noone )
		.setVisible(true, true);
	
	inputs[| 1] = nodeValue("Positions", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 0] )
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 2] = nodeValue("Scales", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 0] )
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 3] = nodeValue("Rotations", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 );
	
	inputs[| 4] = nodeValue("Blends", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, 0 );
	
	inputs[| 5] = nodeValue("Alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 );
	
	inputs[| 6] = nodeValue("Velocity", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 0] )
		.setDisplay(VALUE_DISPLAY.vector);
		
	outputs[| 0] = nodeValue("Object", self, JUNCTION_CONNECT.output, VALUE_TYPE.rigid, noone );
	
	static update = function(frame = CURRENT_FRAME) {
		var objNode = getInputData(0);
		outputs[| 0].setValue(objNode);
		if(!variable_struct_exists(objNode, "object")) return;
		var objs = objNode.object;
		
		var _pos = getInputData(1);
		var _sca = getInputData(2);
		var _rot = getInputData(3);
		var _col = getInputData(4);
		var _alp = getInputData(5);
		var _vel = getInputData(6);
		
		for( var i = 0, n = array_length(objs); i < n; i++ ) {
			var obj = objs[i];
			if(obj == noone || !instance_exists(obj)) continue;
			if(is_undefined(obj.phy_active)) continue;
			
			if(is_array(_pos) && array_length(_pos)) {
				if(is_array(_pos[0])) {
					obj.x = _pos[i][0];
					obj.y = _pos[i][1];
				} else {
					obj.x = _pos[0];
					obj.y = _pos[1];
				}
			}
			
			if(is_array(_sca) && array_length(_sca)) {
				if(is_array(_sca[0])) {
					obj.xscale = _sca[i][0];
					obj.yscale = _sca[i][1];
				} else {
					obj.xscale = _sca[0];
					obj.yscale = _sca[1];
				}
			}
			
			if(is_array(_rot) && array_length(_rot) > i)
				obj.image_angle = _rot[i];
			
			if(is_array(_col) && array_length(_col) > i)
				obj.image_blend = _col[i];
			
			if(is_array(_alp) && array_length(_alp) > i)
				obj.image_alpha = _alp[i];
			
			if(is_array(_vel) && array_length(_vel) > i && is_array(_vel[i])) {
				obj.phy_linear_velocity_x = _vel[i][0];
				obj.phy_linear_velocity_y = _vel[i][1];
			}
		}
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		draw_sprite_fit(node_draw_icon, 0, bbox.xc, bbox.yc, bbox.w, bbox.h);
	}
}