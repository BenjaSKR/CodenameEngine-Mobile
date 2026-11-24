package funkin.options.categories;

import flixel.input.keyboard.FlxKey;
import lime.system.System as LimeSystem;
import funkin.backend.assets.ModsFolder;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class MobileOptions extends TreeMenuScreen
{
	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');
		trace(daList);

		return daList;
	}
	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		if(Assets.exists(path)) daList = Assets.getText(path);
		trace(daList);
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function mergeAllTextsNamed(file:String)
	{
		var mergedList:Array<String> = [];
		var list:Array<String> = coolTextFile(file);
		for (value in list)
			if(!mergedList.contains(value) && value.length > 0)
				mergedList.push(value);
		return mergedList;
	}

	var HitboxModes:Array<String>;
	public function new()
	{
		super('optionsTree.mobile-name', 'optionsTree.mobile-name', 'MobileOptions.', ['LEFT_FULL', 'A_B']);
		HitboxModes = mergeAllTextsNamed("assets/mobile/Hitbox/HitboxModes/hitboxModeList.txt");
		if ((HitboxModes == null))
			HitboxModes = ["Normal"];

		add(new NumOption(getNameID('extraButtons'), getDescID('extraButtons'), 0, 4, 1, 'extraButtons'));
		add(new ArrayOption(getNameID('hitboxType'), getDescID('hitboxType'), ["No Gradient", "No Gradient (Old)", "Gradient"],
			["No Gradient", "No Gradient (Old)", "Gradient"], 'hitboxType'));
		add(new ArrayOption(getNameID('hitboxMode'), getDescID('hitboxMode'), HitboxModes, HitboxModes, 'hitboxMode'));
		add(new Checkbox(getNameID('hitboxPos'), getDescID('hitboxPos'), "hitboxPos"));
		add(new NumOption(getNameID('hitboxAlpha'), getDescID('hitboxAlpha'), 0.0, 1.0, 0.1, "hitboxAlpha", (alpha:Float) ->
		{
			var hb = MusicBeatState.instance.mobileManager.hitbox;
			if (hb != null) hb.alpha = mobile.MobileControlManager.visibleAlpha(alpha);
		}));
		add(new NumOption(getNameID('controlsAlpha'), getDescID('controlsAlpha'), 0.0, 1.0, 0.1, "controlsAlpha", (alpha:Float) ->
		{
			var pad = MusicBeatState.instance.mobileManager.mobilePad;
			if (pad != null) pad.alpha = mobile.MobileControlManager.visibleAlpha(alpha);
			if (funkin.backend.system.Controls.instance.mobileC)
			{
				FlxG.sound.volumeUpKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.muteKeys = [];
			}
			else
			{
				FlxG.sound.volumeUpKeys = [FlxKey.PLUS, FlxKey.NUMPADPLUS];
				FlxG.sound.volumeDownKeys = [FlxKey.MINUS, FlxKey.NUMPADMINUS];
				FlxG.sound.muteKeys = [FlxKey.ZERO, FlxKey.NUMPADZERO];
			}
		}));
	}

	override function close()
	{
		super.close();
	}
}
