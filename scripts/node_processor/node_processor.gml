enum ARRAY_PROCESS {
	loop,
	hold,
	expand,
	expand_inv,
}

#macro PROCESSOR_OVERLAY_CHECK if(array_length(current_data) != ds_list_size(inputs)) return;

function Node_Processor(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	attributes.array_process = ARRAY_PROCESS.loop;
	current_data	= [];
	inputs_data		= [];
	inputs_is_array = [];
	all_inputs      = [];
	
	process_amount	= 0;
	process_length  = [];
	dimension_index = 0;
	
	manage_atlas = true;
	atlas_index  = 0;
	
	batch_output = false;	//Run processData once with all outputs as array.
	
	icon    = THEME.node_processor;
	
	array_push(attributeEditors, "Array processor");
	array_push(attributeEditors, [ "Array process type", function() { return attributes.array_process; }, 
		new scrollBox([ "Loop", "Hold", "Expand", "Expand inverse" ], 
		function(val) { 
			attributes.array_process = val; 
			triggerRender();
		}, false) ]);
	
	static getInputData = function(index, def = 0) { INLINE return array_safe_get(inputs_data, index, def); }
	
	static processData_prebatch  = function() {}
	static processData_postbatch = function() {}
	
	static processData = function(_outSurf, _data, _output_index, _array_index = 0) { return _outSurf; }
	
	static getSingleValue = function(_index, _arr = preview_index, output = false) { #region
		var _l  = output? outputs : inputs;
		var _n  = _l[| _index];
		var _in = output? _n.getValue() : getInputData(_index);
		
		//print($"Getting value {name} [{_index}, {_arr}]: {_n.isArray()} = {_in}");
		if(!_n.isArray()) return _in;
		
		var _aIndex = _arr;
		if(!is_array(_in)) return 0;
		
		switch(attributes.array_process) {
			case ARRAY_PROCESS.loop :		_aIndex = safe_mod(_arr, array_length(_in)); break;
			case ARRAY_PROCESS.hold :		_aIndex = min(_arr, array_length(_in) - 1);  break;
			case ARRAY_PROCESS.expand :		_aIndex = floor(_arr / process_length[_index][1]) % process_length[_index][0]; break;
			case ARRAY_PROCESS.expand_inv : _aIndex = floor(_arr / process_length[ds_list_size(_l) - 1 - _index][1]) % process_length[_index][0]; break;
		}
		
		//print($"Getting value {name} [{_index}, {_arr}]: {_in}[{_aIndex}] = {array_safe_get(_in, _aIndex)}");
		return array_safe_get(_in, _aIndex);
	} #endregion
	
	static getDimension = function(arr = 0) { #region
		if(dimension_index == -1) return [1, 1];
		
		var _in = getSingleValue(dimension_index, arr);
		
		if(inputs[| dimension_index].type == VALUE_TYPE.surface && is_surface(_in)) {
			var ww = surface_get_width_safe(_in);
			var hh = surface_get_height_safe(_in);
			return [ww, hh];
		}
		
		if(is_array(_in) && array_length(_in) == 2)
			return _in;
			
		return [1, 1];
	} #endregion
	
	static processDataArray = function(outIndex) { #region
		var _output = outputs[| outIndex];
		var _out    = _output.getValue();
		var _atlas  = false;
		var _pAtl   = noone;
		var _data   = array_create(ds_list_size(inputs));
		
		if(process_amount == 1) { #region render single data
			if(_output.type == VALUE_TYPE.d3object) //passing 3D vertex call
				return _out;
			
			for(var i = 0; i < ds_list_size(inputs); i++)
				_data[i] = inputs_data[i];
			
			if(_output.type == VALUE_TYPE.surface) {								// Surface preparation
				if(manage_atlas) {
					_pAtl  = _data[atlas_index];
					_atlas = is_instanceof(_pAtl, SurfaceAtlas);
					
					if(_atlas) _data[atlas_index] = _pAtl.getSurface();
				}
				
				if(dimension_index > -1) {
					var surf = _data[dimension_index];
					var _sw = 1, _sh = 1;
					if(inputs[| dimension_index].type == VALUE_TYPE.surface) {
						if(is_surface(surf)) {
							_sw = surface_get_width_safe(surf);
							_sh = surface_get_height_safe(surf);
						} else 
							return noone;
					} else if(is_array(surf)) {
						_sw = array_safe_get(surf, 0, 1);
						_sh = array_safe_get(surf, 1, 1);
					}
					
					if(manage_atlas && is_instanceof(_out, SurfaceAtlas)) {
						surface_free_safe(_out.getSurface())
						_out = surface_verify(_out.getSurface(), _sw, _sh, attrDepth());
					} else
						_out = surface_verify(_out, _sw, _sh, attrDepth());
				}
			}
			
			current_data = _data;
			
			if(active_index > -1 && !_data[active_index]) { // skip
				if(inputs[| 0].type == VALUE_TYPE.surface)
					return surface_clone(_data[0], _out);
				else 
					return _data[0];
			}
			
			var data = processData(_out, _data, outIndex, 0);					// Process data
			
			if(manage_atlas && _atlas && is_surface(data)) {										// Convert back to atlas
				var _atl = _pAtl.clone();
				_atl.setSurface(data);
				return _atl;
			}
			
			return data;
		} #endregion
		
		#region ++++ array preparation ++++
			if(!is_array(_out))
				_out = array_create(process_amount);
			else if(array_length(_out) != process_amount) 
				array_resize(_out, process_amount);
		#endregion
		
		for(var l = 0; l < process_amount; l++) {
			for(var i = 0; i < ds_list_size(inputs); i++)
				_data[i] = all_inputs[i][l];
			
			if(_output.type == VALUE_TYPE.surface) { #region						// Output surface verification
				if(manage_atlas) {
					_pAtl  = _data[atlas_index];
					_atlas = is_instanceof(_pAtl, SurfaceAtlas);
					
					if(_atlas) _data[atlas_index] = _pAtl.getSurface();
				}
				
				if(dimension_index > -1) {
					var surf = _data[dimension_index];
					var _sw = 1, _sh = 1;
					if(inputs[| dimension_index].type == VALUE_TYPE.surface) {
						if(is_surface(surf)) {
							_sw = surface_get_width_safe(surf);
							_sh = surface_get_height_safe(surf);
						} else 
							return noone;
					} else if(is_array(surf)) {
						_sw = surf[0];
						_sh = surf[1];
					}
					
					if(manage_atlas && is_instanceof(_out[l], SurfaceAtlas)) {
						surface_free_safe(_out[l].surface.surface)
						_out[l] = surface_verify(_out[l].getSurface(), _sw, _sh, attrDepth());
					} else
						_out[l] = surface_verify(_out[l], _sw, _sh, attrDepth());
				}
			} #endregion
			
			if(l == 0 || l == preview_index) 
				current_data = _data;
			
			if(active_index > -1 && !_data[active_index]) { // skip
				if(!_atlas && inputs[| 0].type == VALUE_TYPE.surface)
					_out[l] = surface_clone(_data[0], _out[l]);
				else 
					_out[l] = _data[0];
			} else {
				_out[l] = processData(_out[l], _data, outIndex, l);					// Process data
				
				if(manage_atlas && _atlas && is_surface(_out[l])) {					// Convert back to atlas
					var _atl = _pAtl.clone();
					_atl.setSurface(_out[l]);
					_out[l] = _atl;
				}
			}
		}
		
		return _out;
	} #endregion
	
	static processBatchOutput = function() { #region
		for(var i = 0; i < ds_list_size(outputs); i++) {
			if(outputs[| i].type != VALUE_TYPE.surface) continue;
			var _res = outputs[| i].getValue();
			surface_array_free(_res);
			outputs[| i].setValue(noone);
		}
		
		if(process_amount == 1) {
			var data = processData(noone, inputs_data, 0, 0);
			for(var i = 0; i < ds_list_size(outputs); i++) {
				var _outp = array_safe_get(data, i, undefined);
				if(_outp == undefined) continue;
				outputs[| i].setValue(_outp);
			}
		} else {
			var _outputs = array_create(ds_list_size(outputs));
			for( var l = 0; l < process_amount; l++ ) {
				var _data = array_create(ds_list_size(inputs));
				for(var i = 0; i < ds_list_size(inputs); i++)
					_data[i] = all_inputs[i][l];
				
				var data = processData(0, _data, 0, l);
				for(var i = 0; i < ds_list_size(outputs); i++) {
					var _outp = array_safe_get(data, i, undefined);
					_outputs[i][l] = _outp;
				}
			}
				
			for( var i = 0, n = ds_list_size(outputs); i < n; i++ )
				outputs[| i].setValue(_outputs[i]);
		}
	} #endregion
	
	static processOutput = function() { #region
		var val;
		
		for(var i = 0; i < ds_list_size(outputs); i++) {
			if(outputs[| i].process_array) {
				val = processDataArray(i);
				if(val == undefined) continue;
			} else
				val = processData(noone, noone, i);
			outputs[| i].setValue(val);
		}
	} #endregion
	
	static preGetInputs = function() {}
	
	static getInputs = function() { #region
		preGetInputs();
		
		var _len = ds_list_size(inputs);
		
		process_amount	= 1;
		inputs_data		= array_verify(inputs_data,		_len);
		inputs_is_array	= array_verify(inputs_is_array, _len);
		process_length  = array_verify(process_length,	_len);
		all_inputs      = array_verify(all_inputs,		_len);
		
		for(var i = 0; i < _len; i++) {
			var val = inputs[| i].getValue();
			var amo = inputs[| i].arrayLength(val);
			
			if(amo == 0)      val = noone;		//empty array
			else if(amo == 1) val = val[0];		//spread single array
			amo = max(1, amo);
			
			setInputData(i, val);
			inputs_is_array[i] = inputs[| i].isArray(val);
			
			switch(attributes.array_process) {
				case ARRAY_PROCESS.loop : 
				case ARRAY_PROCESS.hold :   
					process_amount = max(process_amount, amo);	
					break;
					
				case ARRAY_PROCESS.expand : 
				case ARRAY_PROCESS.expand_inv : 
					process_amount *= amo;
					break;
			}
			
			process_length[i] = [amo, process_amount];
		}
		
		var amoMax = process_amount;
		for( var i = 0; i < _len; i++ ) {
			amoMax /= process_length[i][0];
			process_length[i][1] = amoMax;
		}
		
		for(var i = 0; i < _len; i++)
			all_inputs[i] = array_verify(all_inputs[i], process_amount);
		
		for(var l = 0; l < process_amount; l++) #region input preparation
		for(var i = 0; i < _len; i++) { 
			var _in = inputs_data[i];
				
			if(!inputs_is_array[i]) {
				all_inputs[i][l] = _in;
				continue;
			}
				
			if(array_length(_in) == 0) {
				all_inputs[i][l] = 0;
				continue;
			}
				
			var _index = 0;
			switch(attributes.array_process) {
				case ARRAY_PROCESS.loop :		_index = safe_mod(l, array_length(_in)); break;
				case ARRAY_PROCESS.hold :		_index = min(l, array_length(_in) - 1);  break;
				case ARRAY_PROCESS.expand :		_index = floor(l / process_length[i][1]) % process_length[i][0]; break;
				case ARRAY_PROCESS.expand_inv : _index = floor(l / process_length[ds_list_size(inputs) - 1 - i][1]) % process_length[i][0]; break;
			}
				
			all_inputs[i][l] = inputs[| i].arrayBalance(_in[_index]);
		} #endregion
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		processData_prebatch();
		if(batch_output) processBatchOutput();
		else			 processOutput();
		processData_postbatch();
		
		postProcess();
	} #endregion
	
	static postProcess = function() {}
	
	static processSerialize = function(_map) { #region
		_map.array_process = attributes.array_process;
	} #endregion
	
	static processDeserialize = function() { #region
		attributes.array_process = struct_try_get(load_map, "array_process", ARRAY_PROCESS.loop);
	} #endregion
	
	///////////////////// CACHE /////////////////////
	
	static cacheCurrentFrameIndex = function(_frame, index) { #region
		cacheArrayCheck();
		if(CURRENT_FRAME < 0) return;
		if(CURRENT_FRAME >= array_length(cached_output)) return;
		
		var prev = cached_output[CURRENT_FRAME];
		surface_array_free(array_safe_get(prev, index));
		cached_output[CURRENT_FRAME][index] = surface_array_clone(_frame);
		
		array_safe_set(cache_result, CURRENT_FRAME, true);
		
		return cached_output[CURRENT_FRAME];
	} #endregion
	
	static getCacheFrameIndex = function(frame = CURRENT_FRAME, index = 0) { #region
		if(frame < 0) return false;
		if(!cacheExist(frame)) return noone;
		
		var surf = array_safe_get(cached_output, frame);
		return array_safe_get(surf, index);
	} #endregion
}