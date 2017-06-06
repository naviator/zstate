package ;
import io.github.naviator.zstate.ZStateMachine;
import haxe.unit.TestCase;
class ZLinkedStateTest extends TestCase {

    private var fsm:ZStateMachine<String>;
    private var target:CustomTargetObject;

    public function new() {
        super();
    }

    override public function setup():Void {
        fsm = new ZStateMachine<String>();
        target = new CustomTargetObject();
    }

    public function setupSimple():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyInt");
        fsm.setDefaultValue(0);
    }

    public function testLinkedMachine():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyInt");
        fsm.setDefaultValue(0);

        fsm.setState("ONE");

        assertEquals(0, target.propertyInt);

        var secondMachine:ZStateMachine<String> = new ZStateMachine<String>();
        secondMachine.addStates(["default2","ONE2", "TWO2"]);

        fsm.addMachine(secondMachine);

        assertEquals(0, target.propertyInt);

        fsm.setValue(1, ["ONE", "ONE2"]);

        assertEquals(0, target.propertyInt);

        secondMachine.setState("ONE2");

        assertEquals(1, target.propertyInt);
    }

    public function testLazyLinkedMachine():Void {

        setupSimple();

        fsm.setState("ONE");

        assertEquals(0, target.propertyInt);

        var secondMachine:ZStateMachine<String> = new ZStateMachine<String>();
        fsm.addMachine(secondMachine);

        secondMachine.addStates(["default2","ONE2", "TWO2"]);

        assertEquals(0, target.propertyInt);

        fsm.setValue(1, ["ONE", "ONE2"]);

        assertEquals(0, target.propertyInt);

        secondMachine.setState("ONE2");

        assertEquals(1, target.propertyInt);
    }

    public function testRemoveMachine():Void {

        setupSimple();

        var secondMachine:ZStateMachine<String> = new ZStateMachine<String>();
        secondMachine.addStates(["default2","ONE2", "TWO2"]);

        fsm.addMachine(secondMachine);

        // setup values
        fsm.setValue(1, ["ONE", "ONE2"]);
        fsm.setValue(2, ["default", "ONE2"]);
        fsm.setState("default");
        secondMachine.setState("ONE2");

        assertEquals(2, target.propertyInt);

        fsm.removeMachine(secondMachine);

        assertEquals(0, target.propertyInt);
    }

}
