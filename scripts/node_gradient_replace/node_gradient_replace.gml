function Node_Gradient_Replace_Color(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name		= "Gradient Replace";
	previewable = false;
	
	w = 96;
	
	inputs[| 0] = nodeValue("Gradient", self, JUNCTION_CONNECT.input, VALUE_TYPE.gradient, new gradientObject(c_white) )
		.setVisible(true, true);
	
	inputs[| 1] = nodeValue("Color from", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, DEF_PALETTE )
		.setDisplay(VALUE_DISPLAY.palette);
	
	inputs[| 2] = nodeValue("Color to", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, DEF_PALETTE )
		.setDisplay(VALUE_DISPLAY.palette);
	
	inputs[| 3] = nodeValue("Threshold", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	outputs[| 0] = nodeValue("Gradient", self, JUNCTION_CONNECT.output, VALUE_TYPE.gradient, new gradientObject(c_white) );
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var gra  = _data[0];
		var pfr  = _data[1];
		var pto  = _data[2];
		var thr  = _data[3];
		var graO = new gradientObject();
		
		for( var i = 0, n = array_length(gra.keys); i < n; i++ ) {
			var k = gra.keys[i];
			
			var fromValue = 999;
			var fromIndex = -1;
			for( var j = 0; j < array_length(pfr); j++ ) {
				var fr = pfr[j];
				
				var dist = color_diff(k.value, fr);
				if(dist <= thr && dist < fromValue) {
					fromValue = dist;
					fromIndex = j;
				}
			}
			
			var cTo = fromIndex == -1? k.value : array_safe_get(pto, fromIndex, k.value, ARRAY_OVERFLOW.loop);
			graO.keys[i] = new gradientKey(k.time, cTo);
		}
		
		graO.type = gra.type;
		
		return graO;
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		if(bbox.h < 1) return;
		
		var grad = outputs[| 0].getValue();
		if(is_array(grad)) {
			if(array_length(grad) == 0) return;
			grad = grad[0];
		}
		
		grad.draw(bbox.x0, bbox.y0, bbox.w, bbox.h);
	}
}