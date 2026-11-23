package funkin.game;

import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.backend.chart.ChartData;
import funkin.backend.scripting.events.note.NoteCreationEvent;
import funkin.backend.system.Conductor;

using StringTools;

@:allow(funkin.game.PlayState)
class Note extends FlxSprite
{
	// CACHÉ ESTÁTICO PARA EVITAR CARGAR LAS TEXTURAS MILES DE VECES
	private static var __cachedFrames:Map<String, FlxAtlasFrames> = new Map();

	public var extra:Map<String, Dynamic> = [];
	public var strumTime:Float = 0;
	public var mustPress(get, never):Bool;

	public var strumLine(default, set):StrumLine;
	private function set_strumLine(strLine:StrumLine) {
		if (this.strumLine != null) {
			if (this.strumLine.notes != null) this.strumLine.notes.remove(this, true);
			strLine.notes.add(this);
			strLine.notes.sortNotes();
		}
		return strumLine = strLine;
	}

	private inline function get_mustPress():Bool return false;

	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var avoid:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var nextSustain:Note;
	public var sustainParent:Null<Note>;
	public var tailCount:Int = 0;
	public var splash:String = "default";

	public var strumID(get, never):Int;
	private function get_strumID() {
		var id = noteData % strumLine.members.length;
		if (id < 0) id = 0;
		return id;
	}

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noSustainClip:Bool = false;
	public var flipSustain:Bool = true;
	public var noteTypeID:Int = 0;

	public var scrollSpeed:Null<Float> = null;
	public var noteAngle:Null<Float> = null;
	public var copyStrumAngle:Bool = true;
	public var updateNotesPosX:Bool = true;
	public var updateNotesPosY:Bool = true;
	public var updateFlipY:Bool = true;
	public var noteType(get, never):String;

	@:dox(hide) public var __strumCameras:Array<FlxCamera> = null;
	@:dox(hide) public var __strum:Strum = null;
	@:dox(hide) public var __noteAngle:Float = 0;

	private function get_noteType() {
		if (PlayState.instance == null) return null;
		return PlayState.instance.getNoteType(noteTypeID);
	}

	public static var swagWidth:Float = 160 * 0.7;

	private static var __customNoteTypeExists:Map<String, Bool> = [];
	public var animSuffix:String = null;
	@:dox(hide) public var tripTimer:Float = 0;

	private static function customTypePathExists(path:String) {
		if (__customNoteTypeExists.exists(path)) return __customNoteTypeExists[path];
		return __customNoteTypeExists[path] = Assets.exists(path);
	}

	static var DEFAULT_FIELDS:Array<String> = ["time", "id", "type", "sLen"];

	public function new(strumLine:StrumLine, noteData:ChartNote, sustain:Bool = false, sustainLength:Float = 0, sustainOffset:Float = 0, ?prev:Note) {
		super();

		moves = false;

		if(prev != null) this.prevNote = prev;
		else this.prevNote = strumLine.notes.members.last();

		if (this.prevNote != null) this.prevNote.nextNote = this;
		this.noteTypeID = noteData.type.getDefault(0);
		this.isSustainNote = sustain;
		this.sustainLength = sustainLength;
		this.strumLine = strumLine;
		for(field in Reflect.fields(noteData)) if(!DEFAULT_FIELDS.contains(field))
			this.extra.set(field, Reflect.field(noteData, field));

		if (isSustainNote) sustainParent = prevNote.isSustainNote ? prevNote.sustainParent : prevNote;

		x += 50;
		y -= 2000;

		this.strumTime = noteData.time.getDefault(0) + sustainOffset;
		this.noteData = noteData.id.getDefault(0);

		var customType = Paths.image('game/notes/${this.noteType}');
		var event = EventManager.get(NoteCreationEvent).recycle(this, strumID, this.noteType, noteTypeID, PlayState.instance.strumLines.members.indexOf(strumLine), mustPress,
			(this.noteType != null && customTypePathExists(customType)) ? 'game/notes/${this.noteType}' : 'game/notes/default', @:privateAccess strumLine.strumScale * Flags.DEFAULT_NOTE_SCALE, animSuffix);

		if (PlayState.instance != null) event = PlayState.instance.gameAndCharsEvent("onNoteCreation", event);

		this.animSuffix = event.animSuffix;
		if (!event.cancelled) {
			switch (event.noteType) {
				default:
					// --- INICIO DE LA OPTIMIZACIÓN DE CACHÉ ---
					var spritePath = event.noteSprite;
					if (!__cachedFrames.exists(spritePath)) {
						__cachedFrames.set(spritePath, Paths.getFrames(spritePath));
					}
					frames = __cachedFrames.get(spritePath);
					// --- FIN DE LA OPTIMIZACIÓN DE CACHÉ ---

					switch(event.strumID % 4) {
						case 0:
							animation.addByPrefix('scroll', 'purple0');
							animation.addByPrefix('hold', 'purple hold piece');
							animation.addByPrefix("holdend", "pruple end hold");
							if (animation.exists("holdend") != true) animation.addByPrefix('holdend', 'purple hold end');
						case 1:
							animation.addByPrefix('scroll', 'blue0');
							animation.addByPrefix('hold', 'blue hold piece');
							animation.addByPrefix('holdend', 'blue hold end');
						case 2:
							animation.addByPrefix('scroll', 'green0');
							animation.addByPrefix('hold', 'green hold piece');
							animation.addByPrefix('holdend', 'green hold end');
						case 3:
							animation.addByPrefix('scroll', 'red0');
							animation.addByPrefix('hold', 'red hold piece');
							animation.addByPrefix('holdend', 'red hold end');
					}
					scale.set(event.noteScale, event.noteScale);
					antialiasing = true;
			}
		}

		updateHitbox();

		if (isSustainNote && prevNote != null) {
			alpha = 0.6;
			animation.play('holdend');
			updateHitbox();
			if (prevNote.isSustainNote) {
				prevNote.nextSustain = this;
				prevNote.animation.play('hold');
			}
		} else animation.play("scroll");

		if (PlayState.instance != null) {
			PlayState.instance.splashHandler.getSplashGroup(splash);
			PlayState.instance.gameAndCharsEvent("onPostNoteCreation", event);
		}
	}

	public var lastScrollSpeed:Null<Float> = null;
	public var gapFix:SingleOrFloat = 0;
	public var useAntialiasingFix(get, set):Bool;

	inline function set_useAntialiasingFix(v:Bool) {
		if(v != useAntialiasingFix) gapFix = v ? 1 : 0;
		return v;
	}
	inline function get_useAntialiasingFix() return gapFix>0;

	public var strumRelativePos:Bool = true;

	@:dox(hide) static var __lastAngle:Float = Math.NaN;
	@:dox(hide) static var __lastAngleSin:Float = 0;
	@:dox(hide) static var __lastAngleCos:Float = 0;
	@:dox(hide) static var __lastStrumW:Float = Math.NaN;
	@:dox(hide) static var __lastStrumH:Float = Math.NaN;
	@:dox(hide) static var __lastStrumHalfW:Float = 0;
	@:dox(hide) static var __lastStrumHalfH:Float = 0;

	override function draw() {
		@:privateAccess var oldDefaultCameras = FlxCamera._defaultCameras;
		@:privateAccess if (__strumCameras != null) FlxCamera._defaultCameras = __strumCameras;

		var negativeScroll = isSustainNote && strumRelativePos && lastScrollSpeed < 0;
		if (negativeScroll) y -= height;
		if (__strum != null && strumRelativePos) {
			final originalX = x;
			final originalY = y;

			if (__noteAngle != __lastAngle) {
				__lastAngle = __noteAngle;
				final result = FlxMath.fastSinCos((__noteAngle + 90) * FlxAngle.TO_RAD);
				__lastAngleSin = result.sin;
				__lastAngleCos = result.cos;
			}

			if (__strum.width != __lastStrumW || __strum.height != __lastStrumH) {
				__lastStrumW = __strum.width;
				__lastStrumH = __strum.height;
				__lastStrumHalfW = __strum.width * 0.5;
				__lastStrumHalfH = __strum.height * 0.5;
			}

			x = -origin.x + offset.x + (originalY * __lastAngleCos) + __strum.x + __lastStrumHalfW;
			y = -origin.y + offset.y + (originalY * __lastAngleSin) + __strum.y + __lastStrumHalfH;
			super.draw();
			x = originalX;
			y = originalY;
		} else super.draw();
		
		if (negativeScroll) y += height;
		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}

	var __lastDownscrollCam:Bool = false;
	var __lastX:Float = 0;

	@:noCompletion @:dox(hide) override function isOnScreen(?camera:FlxCamera):Bool {
		var downscrollCam = (Std.isOfType(camera, HudCamera) ? cast(camera, HudCamera).downscroll : false);
		if (downscrollCam == __lastDownscrollCam) return super.isOnScreen(camera);
		else __lastX = x;

		if (updateFlipY) flipY = (isSustainNote && flipSustain) && (downscrollCam != (__strum != null && __strum.getScrollSpeed(this) < 0));
		if (downscrollCam && __strum != null) x = -x + 2 * (__strum.x - origin.x + offset.x) + __strum.width;
		return super.isOnScreen(camera);
	}

	override function drawComplex(camera:FlxCamera):Void {
		super.drawComplex(camera);
		if (__lastDownscrollCam) {
			__lastDownscrollCam = false;
			x = __lastX;
		}
	}

	public function isOnScreenOriginal(?camera:FlxCamera):Bool return super.isOnScreen(camera);

	public var earlyPressWindow:Float = 0.5;
	public var latePressWindow:Float = 1;

	public function updateSustain(strum:Strum) {
		var scrollSpeed = strum.getScrollSpeed(this);
		if (lastScrollSpeed != scrollSpeed) {
			lastScrollSpeed = scrollSpeed;
			if (nextSustain != null) {
				scale.y = (sustainLength * 0.45 * scrollSpeed) / frameHeight;
				updateHitbox();
				scale.y += gapFix / frameHeight;
			}
		}
		updateSustainClip();
	}

	public function updateSustainClip() if (wasGoodHit && !noSustainClip) {
		var t = CoolUtil.bound((Conductor.songPosition - strumTime) / height * 0.45 * lastScrollSpeed, 0, 1);
		@:bypassAccessor {
			if (clipRect == null) clipRect = FlxRect.get();
			clipRect.set(0, frameHeight * t, frameWidth, frameHeight * (1 - t));
		}
		@:privateAccess {
			if (frame != null && _frame != null) _frame = frame.clipTo(clipRect, _frame);
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect {
		@:bypassAccessor clipRect = rect;
		@:privateAccess if (frame != null) {
			if (rect != null && _frame != null) _frame = frame.clipTo(rect, _frame);
			else if (_frame != null) _frame = frame.copyTo(_frame);
			dirty = true;
		}
		return rect;
	}

	public override function destroy() {
		super.destroy();
		clipRect = FlxDestroyUtil.put(clipRect);
	}
}
