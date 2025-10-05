package collectables;

import events.gen.Event.SealCollected;
import events.EventBus;

class CollectStats {
    public final levelName:String;
    public final maxNumCollectables:Int;
    public var curNumCollected:Int;
    public var highestNumCollected:Int;

    public function new(levelName:String, maxNumCollectables:Int) {
        this.levelName = levelName;
        this.maxNumCollectables = maxNumCollectables;
    }
}

class Collectables {
    private static var levelToStats:Map<String, CollectStats> = new Map();
    private static var currentLevelName:String;

    public static function initLevel(levelName: String, maxNumCollectables:Int) {
        var stats = levelToStats.get(levelName);
        if (stats == null) {
            stats = new CollectStats(levelName, maxNumCollectables);
        }

        stats.curNumCollected = 0;
        levelToStats.set(levelName, stats);
        currentLevelName = levelName;

        EventBus.fire(new SealCollected(stats.curNumCollected, stats.maxNumCollectables));
    }

    public static function getStats(levelName:String): Null<CollectStats> {
        return levelToStats.get(levelName);
    }

    public static function incrCollect() {
        var stats = levelToStats.get(currentLevelName);
        stats.curNumCollected++;

        setStats(stats);
    }

    public static function resetCollected(levelName:String, numAliveCollectables:Int) {
        var stats = levelToStats.get(levelName);
        stats.curNumCollected = stats.maxNumCollectables - numAliveCollectables;

        setStats(stats);
    }

    private static function setStats(stats: CollectStats) {
        if (stats.curNumCollected > stats.highestNumCollected) {
            stats.highestNumCollected = stats.curNumCollected;
        }
        levelToStats.set(stats.levelName, stats);

		EventBus.fire(new SealCollected(stats.curNumCollected, stats.maxNumCollectables));
    }
}