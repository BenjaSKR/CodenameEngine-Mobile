package funkin.backend.assets;

import openfl.utils.AssetLibrary;
import funkin.backend.utils.AssetTimer;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

#if MOD_SUPPORT
import sys.FileStat;
import sys.FileSystem;
#end

using StringTools;

class ModsFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var basePath:String;
	public var modName:String;
	public var libName:String;
	//public var useImageCache:Bool = true;
	public var prefix = 'assets/';

	public function new(basePath:String, libName:String, ?modName:String) {
		this.basePath = basePath;
		this.libName = libName;
		this.prefix = 'assets/$libName/';
		this.modName = modName == null ? libName : modName;
		super();
	}

	function toString():String {
		return '(ModsFolderLibrary: $modName)';
	}

	#if MOD_SUPPORT
	private var editedTimes:Map<String, Float> = [];
	public var _parsedAsset:String = null;

	public function getEditedTime(asset:String):Null<Float> {
		return editedTimes[asset];
	}

	public override function getAudioBuffer(id:String):AudioBuffer {
		var __top = AssetTimer.enter(), __t = AssetTimer.now();
		if (!exists(id, "SOUND")) {
			AssetTimer.leave();
			return null;
		}
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		var e = AudioBuffer.fromFile(path);
		// LimeAssets.cache.audio.set('$libName:$id', e);
		AssetTimer.leave();
		if (__top) AssetTimer.add("audio (decodificar)", id, __t);
		return e;
	}

	public override function getBytes(id:String):Bytes {
		var __top = AssetTimer.enter(), __t = AssetTimer.now();
		if (!exists(id, "BINARY")) {
			AssetTimer.leave();
			return null;
		}
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		var e = Bytes.fromFile(path);
		AssetTimer.leave();
		if (__top) AssetTimer.add("texto/json/xml/bytes (leer)", id, __t);
		return e;
	}

	public override function getFont(id:String):Font {
		if (!exists(id, "FONT"))
			return null;
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		return ModsFolder.registerFont(Font.fromFile(path));
	}

	public override function getImage(id:String):Image {
		var __top = AssetTimer.enter(), __t = AssetTimer.now();
		if (!exists(id, "IMAGE")) {
			AssetTimer.leave();
			return null;
		}
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();

		var e = Image.fromFile(path);
		AssetTimer.leave();
		if (__top) {
			if (e != null) AssetTimer.addImageSize(e.width, e.height);
			AssetTimer.add("PNG (decodificar)", id, __t, e != null ? e.width + "x" + e.height : "");
		}
		return e;
	}

	public override function getPath(id:String):String {
		var __top = AssetTimer.enter(), __t = AssetTimer.now();
		var __r = __parseAsset(id) ? getAssetPath() : null;
		AssetTimer.leave();
		if (__top) AssetTimer.add("busqueda de rutas (getPath/exists)", id, __t);
		return __r;
	}

	public inline function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	public inline function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);

	public function __getFiles(folder:String, folders:Bool = false) {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];
		var path = getAssetPath();
		try {
			var result:Array<String> = [];
			for(e in FileSystem.readDirectory(path))
				if (FileSystem.isDirectory('$path$e') == folders)
					result.push(e);
			return result;
		} catch(e) {
			// woops!!
		}
		return [];
	}

	// Cache de FileSystem.exists (en /sdcard cada consulta es lenta). Positivos: validos hasta el
	// proximo cambio de state. Negativos: ademas caducan a los 3 s por si un script crea el archivo.
	static var __existsCache:Map<String, Float> = [];

	public static function clearExistsCache():Void
		__existsCache.clear();

	function __fileExists():Bool {
		var path = getAssetPath();
		var c = __existsCache.get(path);
		if (c != null && (c == 0 || Sys.time() - c < 3.0)) return c == 0;
		var r = FileSystem.exists(path);
		__existsCache.set(path, r ? 0 : Sys.time());
		return r;
	}

	public override function exists(asset:String, type:String):Bool {
		var __top = AssetTimer.enter(), __t = AssetTimer.now();
		var __r = __parseAsset(asset) && __fileExists();
		AssetTimer.leave();
		if (__top) AssetTimer.add("busqueda de rutas (getPath/exists)", asset, __t);
		return __r;
	}

	private function getAssetPath() {
		return '$basePath/$_parsedAsset';
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false) {
		if (!editedTimes.exists(asset))
			return false;
		var editedTime = editedTimes[asset];
		if (editedTime == null || editedTime < FileSystem.stat(getPath(asset)).mtime.getTime()) {
			// destroy already existing to prevent memory leak!!!
			/*var asset = cache[asset];
			if (asset != null) {
				switch(Type.getClass(asset)) {
					case lime.graphics.Image:
						trace("getting rid of image cause replaced");
						cast(asset, lime.graphics.Image);
				}
			}*/
			return false;
		}

		if (!isLocalCache) asset = '$libName:$asset';

		return cache.exists(asset) && cache[asset] != null;
	}

	private function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		if(ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}
		return true;
	}

	public override function list(type:String):Array<String> {
		var result = [];
		__listAppend(result, '');
		return result;
	}

	function __listAppend(arr:Array<String>, folder:String) {
		for(file in FileSystem.readDirectory('$basePath/$folder')) {
			var fullPath = '$basePath/$folder/$file';
			if (FileSystem.isDirectory(fullPath))
				__listAppend(arr, '$folder$file/');
			else
				arr.push('$prefix$folder$file');
		}
	}
	#end

	// Backwards compat

	@:noCompletion public var folderPath(get, set):String;
	@:noCompletion private inline function get_folderPath():String {
		return basePath;
	}
	@:noCompletion private inline function set_folderPath(value:String):String {
		return basePath = value;
	}
}