package collectables;

import flixel.FlxG;
import events.gen.Event.SealCollected;
import events.EventBus;

class SaveData {
	public var levels:Array<CollectStats>;

	public function new() {}

	public static function load():SaveData {
		var saveData:SaveData = cast FlxG.save.data.save;
		if (saveData == null) {
			QLog.notice('Save data is null, created empty save data');
			saveData = new SaveData();
			saveData.levels = new Array<CollectStats>();
		} else {
			QLog.notice('Load save data: ${saveData}');
		}
		return saveData;
	}

	public function add(stats:CollectStats) {
		if (levels == null) {
			levels = new Array<CollectStats>();
		}
		var existing = get(stats.levelName);
		if (existing == null) {
			levels.push(stats);
			return;
		}
		existing.maxNumCollectables = stats.maxNumCollectables;
		if (stats.visited) {
			existing.visited = stats.visited;
		}
		if (stats.completed) {
			existing.completed = stats.completed;
		}
		if (stats.highestNumCollected > existing.highestNumCollected) {
			existing.highestNumCollected = stats.highestNumCollected;
		}
		if (existing.highestNumCollected > existing.maxNumCollectables) {
			existing.highestNumCollected = existing.maxNumCollectables;
		}
	}

	public function get(id:String):Null<CollectStats> {
		if (levels == null) {
			return null;
		}
		for (stats in levels) {
			if (stats != null && stats.levelName == id) {
				return stats;
			}
		}
		return null;
	}

	public function save():Bool {
		FlxG.save.data.save = this;
		var result = FlxG.save.flush();
		QLog.notice('Save Data(${result}): ${this}');
		return result;
	}
}

class CollectStats {
	public final levelName:String;
	public var maxNumCollectables:Int;
	public var curNumCollected:Int;
	public var highestNumCollected:Int;
	public var visited:Bool;
	public var completed:Bool;

	public function new(levelName:String, maxNumCollectables:Int) {
		this.levelName = levelName;
		this.maxNumCollectables = maxNumCollectables;
		curNumCollected = 0;
		highestNumCollected = 0;
		visited = false;
		completed = false;
	}

	public function toString():String {
		var shortLevelName = levelName;
		if (shortLevelName.length > 10) {
			shortLevelName = shortLevelName.substring(0, 7) + "...";
		}
		return '{id:${shortLevelName},${curNumCollected}/${maxNumCollectables}[${highestNumCollected}]${visited ? "vis" : ""} ${completed ? "comp" : ""}}';
	}
}

class Collectables {
	private static var saveData:SaveData;
	private static var currentLevelName:String;

	public static function initLevel(levelName:String, maxNumCollectables:Int) {
		saveData = SaveData.load();
		var stats = saveData.get(levelName);
		if (stats == null) {
			stats = new CollectStats(levelName, maxNumCollectables);
			stats.visited = true;
			saveData.add(stats);
			saveData.save();
		}
		if (!stats.visited) {
			stats.visited = true;
			saveData.save();
		}

		stats.curNumCollected = 0;
		currentLevelName = levelName;

		EventBus.fire(new SealCollected(stats.curNumCollected, stats.maxNumCollectables));
	}

	public static function incrCollect(amount:Int = 1) {
		var stats = saveData.get(currentLevelName);
		stats.curNumCollected += amount;
		if (stats.curNumCollected > stats.highestNumCollected) {
			stats.highestNumCollected = stats.curNumCollected;
			saveData.save();
		}

		EventBus.fire(new SealCollected(stats.curNumCollected, stats.maxNumCollectables));
	}

	public static function complete() {
		var stats = saveData.get(currentLevelName);
		if (!stats.completed) {
			stats.completed = true;
			saveData.save();
		}
	}

	public static function resetCollected() {
		var stats = saveData.get(currentLevelName);
		stats.curNumCollected = 0;

		EventBus.fire(new SealCollected(stats.curNumCollected, stats.maxNumCollectables));
	}
}
