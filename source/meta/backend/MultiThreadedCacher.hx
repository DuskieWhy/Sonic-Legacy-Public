package meta.backend;

import sys.thread.Mutex;
import sys.thread.Thread;

//soon
class MultiThreadedCacher 
{
    var threads:Array<Thread> = [];
    var mutex:Mutex;
    var threadLimit:Int = ClientPrefs.data.loadingThreads;
}

enum AssetType {
    IMAGE;
    SOUND;
    DATA;
}