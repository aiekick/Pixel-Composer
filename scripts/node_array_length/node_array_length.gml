function Node_Array_Length(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name		= "Array Length";
	previewable = false;
	
	w = 96;
	h = 32 + 24;
	min_h = h;
	
	inputs[| 0] = nodeValue("Array", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, 0)
		.setVisible(true, true);
	
	outputs[| 0] = nodeValue("Size", self, JUNCTION_CONNECT.output, VALUE_TYPE.integer, 0);
	
	static step = function() { #region
		inputs[| 0].setType(inputs[| 0].isLeaf()? VALUE_TYPE.any : inputs[| 0].value_from.type);
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		var _arr = getInputData(0);
		
		if(!is_array(_arr) || array_length(_arr) == 0) {
			outputs[| 0].setValue(0);
			return 0;
		}
		
		outputs[| 0].setValue(array_length(_arr));
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		draw_set_text(f_sdf, fa_center, fa_center, COLORS._main_text);
		var str	= string(outputs[| 0].getValue());
		
		var bbox = drawGetBbox(xx, yy, _s);
		var ss	= string_scale(str, bbox.w, bbox.h);
		draw_text_transformed(bbox.xc, bbox.yc, str, ss, ss, 0);
	} #endregion
}