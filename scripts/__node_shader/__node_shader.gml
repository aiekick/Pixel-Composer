enum SHADER_UNIFORM {
	integer,
	float,
	color,
}

function addShaderProp(_type = undefined, _key = undefined) {
	INLINE
	var _ind = ds_list_size(inputs) - 1;
	shader_data[_ind] = _type == undefined? 0 : { type: _type, key: _key };
}

function Node_Shader(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name   = "";
	shader = noone;
	shader_data = [];
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	static setShader = function(_data) { #region
		for( var i = 0, n = array_length(shader_data); i < n; i++ ) {
			var _dat = shader_data[i];
			if(_dat == 0) continue;
			
			var _val = _data[i];
			
			switch(_dat.type) {
				case SHADER_UNIFORM.integer : shader_set_i(_dat.key, _val);     break;
				case SHADER_UNIFORM.float   : shader_set_f(_dat.key, _val);     break;
				case SHADER_UNIFORM.color   : shader_set_color(_dat.key, _val); break;
			}
		}
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region
		return _outSurf;
	} #endregion
}