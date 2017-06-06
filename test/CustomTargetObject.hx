package ;
class CustomTargetObject {

    public var propertyBool:Bool = false;
    public var propertyStr:String = "";
    public var propertyInt:Int = 0;
    public var propertyDynamic:Dynamic;

    public var countedInt(default, set):Int;

    public function new() {
    }

    function set_countedInt(newValue:Int):Int {

        countedInt++;

        return countedInt;
    }
}
