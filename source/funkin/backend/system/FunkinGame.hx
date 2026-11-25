package funkin.backend.system;

import flixel.FlxGame;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	public override function switchState() {
		super.switchState();
		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		var __t = funkin.backend.utils.AssetTimer.now();
		draw();
		funkin.backend.utils.AssetTimer.drawDone(__t);
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t) {
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
	}
}