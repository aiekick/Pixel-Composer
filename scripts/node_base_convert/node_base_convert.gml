function Node_Base_Convert(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name		= "Convert Base";
	color		= COLORS.node_blend_number;
	previewable = false;
	
	w = 96;
	
	inputs[| 0] = nodeValue("Value", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "")
		.setVisible(true, true);
	
	inputs[| 1] = nodeValue("Base from", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 10);
	
	inputs[| 2] = nodeValue("Base to", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 10);
	
	outputs[| 0] = nodeValue("Result", self, JUNCTION_CONNECT.output, VALUE_TYPE.text, "");
	
	static processData = function(_output, _data, _output_index, _array_index = 0) { 
		var val   = _data[0];
		var bFrom = max(2, _data[1]);
		var bTo   = max(2, _data[2]);
		
		return convertBase(val, bFrom, bTo);
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		draw_set_text(f_sdf, fa_center, fa_center, COLORS._main_text);
		var baseFrom = array_safe_get(current_data, 1);
		var baseTo   = array_safe_get(current_data, 2);
		
		var bbox = drawGetBbox(xx, yy, _s);
		var b1   = BBOX().fromPoints(bbox.x0, bbox.y0, bbox.xc - _s * 8, bbox.y1);
		var b2   = BBOX().fromPoints(bbox.xc + _s * 8, bbox.y0, bbox.x1, bbox.y1);
		
		draw_sprite_ext(THEME.arrow, 0, bbox.xc, bbox.yc + 1 * _s, .5 * _s, .5 * _s, 0, COLORS._main_icon, 1);
		draw_text_bbox(b1, baseFrom);
		draw_text_bbox(b2, baseTo);
	}
}