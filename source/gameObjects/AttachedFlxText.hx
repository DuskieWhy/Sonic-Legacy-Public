package gameObjects;

class AttachedFlxText extends FlxText
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var sprTracker:FlxSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;
	public var isCheckBox:Bool = false;
	public var daValue(default,set):Bool = false;

	private function set_daValue(val:Bool):Bool {
		if(isCheckBox){
			if(val){
				text = "TRUE";
				setFormat(Paths.font("cmd.ttf"), 16, FlxColor.GREEN, LEFT);

			}else{
				text = "FALSE";
				setFormat(Paths.font("cmd.ttf"), 16, FlxColor.RED, LEFT);
			}
		}
		return val;
	}

    public function setOffsets(x:Float, y:Float):Void {
        offsetX = x;
        offsetY = y;
    }

	override function update(elapsed:Float) {
		if (sprTracker != null) {
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			if(copyVisible) {
				visible = sprTracker.visible;
			}
			if(copyAlpha) {
				alpha = sprTracker.alpha;
			}
		}

		super.update(elapsed);
	}
}
