function Node_3D_Scene(_x, _y, _group = noone) : Node_3D(_x, _y, _group) constructor {
	name = "3D Scene";
	
	outputs[| 0] = nodeValue("Scene", self, JUNCTION_CONNECT.output, VALUE_TYPE.d3Scene, noone);
	
	setIsDynamicInput(1);
	
	object_lists = [];
	
	static createNewInput = function() { #region
		var index = ds_list_size(inputs);
		inputs[| index] = nodeValue("Object", self, JUNCTION_CONNECT.input, VALUE_TYPE.d3Mesh, noone )
			.setVisible(true, true);
	} #endregion
	if(!LOADING && !APPENDING) createNewInput();
	
	static refreshDynamicInput = function() { #region
		var _l = ds_list_create();
		for( var i = 0; i < ds_list_size(inputs); i++ ) {
			if(i < input_fix_len || inputs[| i].value_from)	
				ds_list_add(_l, inputs[| i]);
			else
				delete inputs[| i];	
		}
		
		for( var i = 0; i < ds_list_size(_l); i++ )
			_l[| i].index = i;
		
		ds_list_destroy(inputs);
		inputs = _l;
		
		createNewInput();
	} #endregion
	
	static onValueFromUpdate = function(index) { #region
		if(index < input_fix_len) return;
		if(LOADING || APPENDING) return;
		
		refreshDynamicInput();
	} #endregion
	
	static processData = function(_output, _data, _output_index, _array_index = 0) { #region
		var _scene = new __3dGroup();
		
		for( var i = input_fix_len, n = ds_list_size(inputs); i < n; i += data_length ) {
			var _obj = _data[i];
			if(_obj == noone) continue;
			
			_scene.addObject(_obj);
		}
		
		return _scene;
	} #endregion
}