package meta;

class MacroData
{
    public static macro function getDate()
        return macro  $v{Date.now().toString()};

    public static macro function getUSR()
        return macro  $v{#if windows Sys.environment()["USERNAME"] #elseif (linux || macos) return Sys.environment()["USER"] #end};
}
