function Node_Audio_Loudness(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name		= "Audio Loudness";
	previewable = false;
	
	w = 96;
	h = 72;
	min_h = h;
	
	inputs[| 0] = nodeValue("Audio Data", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [])
		.setArrayDepth(1)
		.setVisible(true, true);
	
	outputs[| 0] = nodeValue("Loudness", self, JUNCTION_CONNECT.output, VALUE_TYPE.float, 0);
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var _dat = _data[0];
		
		var N    = array_length(_dat);
		var val  = 0;
		if(N == 0) return 0;
		
		for( var i = 0; i < N; i++ )
			val += _dat[i] * _dat[i];
		val = sqrt(val / N);
		
		var dec = 10 * log10(val);
		return dec;
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		draw_sprite_fit(s_node_audio_volume, 0, bbox.xc, bbox.yc, bbox.w, bbox.h);
	}
}