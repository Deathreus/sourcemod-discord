stock bool RenameJsonObject(JSON_Object hJson, char[] key, char[] toKey) {
	if(hJson == null)
		return false;

	switch(hJson.GetKeyType(key))
	{
		case JSON_Type_String: {
			char string[1024];
			hJson.GetString(key, string, sizeof string);
			hJson.Remove(key);
			hJson.SetString(toKey, string);
		}
		case JSON_Type_Int: {
	    	int value = JsonObjectGetInt(hJson, key);
	    	hJson.Remove(key);
	    	hJson.SetInt(toKey, value);
	    }
		case JSON_Type_Float: {
	    	float value = JsonObjectGetFloat(hJson, key);
	    	hJson.Remove(key);
	    	hJson.SetFloat(toKey, value);
	    }
		case JSON_Type_Bool: {
	    	bool value = JsonObjectGetBool(hJson, key);
	    	hJson.Remove(key);
	    	hJson.SetBool(toKey, value);
	    }
		case JSON_Type_Object: {
	    	JSON_Object obj = hJson.GetObject(key);
	    	hJson.Remove(key); // We are moving this, don't delete
	    	hJson.SetObject(toKey, obj);
	    }
		default:
	    	return false;
	}

	return true;
}

stock int JsonObjectGetInt(JSON_Object hObject, char[] key, int defaultvalue=0) {
	if(hObject == null)
		return defaultvalue;
	
	int value;
	if(hObject.GetKeyType(key) == JSON_Type_Int) {
		value = hObject.GetInt(key);
	}else if(hObject.GetKeyType(key) == JSON_Type_String) {
		char buffer[12];
		hObject.GetString(key, buffer, sizeof(buffer));
		value = StringToInt(buffer);
	}else if(hObject.GetKeyType(key) == JSON_Type_Float) {
		value = RoundToFloor(hObject.GetFloat(key));
	}
	
	return value;
}

stock bool JsonObjectGetString(JSON_Object hObject, char[] key, char[] buffer, maxlength) {
	if(hObject == null)
		return false;
	
	if(hObject.GetKeyType(key) == JSON_Type_Int) {
		IntToString(hObject.GetInt(key), buffer, maxlength);
	}else if(hObject.GetKeyType(key) == JSON_Type_String) {
		hObject.GetString(key, buffer, maxlength);
	}else if(hObject.GetKeyType(key) == JSON_Type_Float) {
		FloatToString(hObject.GetFloat(key), buffer, maxlength);
	}else if(hObject.GetKeyType(key) == JSON_Type_Bool) {
		FormatEx(buffer, maxlength, "%s", hObject.GetBool(key) ? "true":"false");
	}
	
	return true;
}

stock bool JsonObjectGetBool(JSON_Object hObject, char[] key, bool defaultvalue=false) {
	if(hObject == null)
		return defaultvalue;
	
	bool value = defaultvalue;
	if(hObject.GetKeyType(key) == JSON_Type_Int) {
		value = view_as<bool>(hObject.GetInt(key));
	}else if(hObject.GetKeyType(key) == JSON_Type_String) {
		char buffer[8];
		hObject.GetString(key, buffer, sizeof(buffer));
		if(StrEqual(buffer, "true", false)) {
			value = true;
		}else if(StrEqual(buffer, "false", false)) {
			value = false;
		}else {
			int x = StringToInt(buffer);
			value = view_as<bool>(x);
		}
	}else if(hObject.GetKeyType(key) == JSON_Type_Float) {
		value = view_as<bool>(RoundToFloor(hObject.GetFloat(key)));
	}else if(hObject.GetKeyType(key) == JSON_Type_Bool) {
		value = hObject.GetBool(key);
	}
	
	return value;
}

stock float JsonObjectGetFloat(JSON_Object hObject, char[] key, float defaultValue=0.0) {
	if(hObject == null)
		return defaultValue;
	
	float value = defaultValue;
	if(hObject.GetKeyType(key) == JSON_Type_Int) {
		value = float(hObject.GetInt(key));
	}else if(hObject.GetKeyType(key) == JSON_Type_Float) {
		value = hObject.GetFloat(key);
	}else if(hObject.GetKeyType(key) == JSON_Type_String) {
		char buffer[12];
		hObject.GetString(key, buffer, sizeof(buffer));
		value = StringToFloat(buffer);
	}
	
	return value;
}
