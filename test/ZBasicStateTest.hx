package ;

import haxe.unit.TestCase;
import io.github.naviator.zstate.ZStateMachine;
class ZBasicStateTest extends TestCase {

    private var fsm:ZStateMachine<String>;
    private var target:CustomTargetObject;

    public function new() {
        super();
    }

    override public function setup():Void {
        fsm = new ZStateMachine<String>();
        target = new CustomTargetObject();
    }

    public function testBasicInt():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyInt");
        fsm.setValue(1, ["ONE"]);
        fsm.setState("ONE");

        assertEquals(1, target.propertyInt);
    }

    public function testBasicString():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyStr");
        fsm.setValue("asdf", ["ONE"]);
        fsm.setState("ONE");

        assertEquals("asdf", target.propertyStr);
    }

    public function testBasicBool():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyBool");
        fsm.setValue(true, ["ONE"]);
        fsm.setState("ONE");

        assertTrue(target.propertyBool);
    }

    public function testBasicObject():Void {

        var value1:CustomTargetObject = new CustomTargetObject();

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyDynamic");
        fsm.setValue(value1, ["ONE"]);

        fsm.setState("ONE");
        assertEquals(value1, target.propertyDynamic);
    }

    public function setupSimple():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyInt");
        fsm.setDefaultValue(0);
    }

    public function testSetMultipleValues():Void {

        setupSimple();

        fsm.addStates(["default2","ONE2", "TWO2"]);
        fsm.setValue(1, ["ONE", "ONE2"]);

        fsm.setState("ONE");
        assertEquals(0, target.propertyInt);

        fsm.setState("ONE2");
        assertEquals(1, target.propertyInt);
    }

    public function testComplexChanges():Void {

        setupSimple();

        fsm.addStates(["default2","ONE2", "TWO2"]);
        fsm.setValue(1, ["ONE"]);
        fsm.setValue(2, ["TWO2"]);

        assertEquals(0, target.propertyInt);

        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.setState("default");
        assertEquals(0, target.propertyInt);

        fsm.setValue(3, ["ONE", "ONE2"]);
        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.setState("TWO2");
        assertEquals(1, target.propertyInt);

        fsm.setState("default");
        assertEquals(2, target.propertyInt);

        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.setState("ONE2");
        assertEquals(3, target.propertyInt);
    }

    public function testSingleSetting():Void {

        fsm.addStates(["default","ONE", "TWO"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("countedInt");
        fsm.setValue(1, ["ONE"]);

        assertEquals(0, target.countedInt);

        fsm.setState("ONE");
        assertEquals(1, target.countedInt);

        fsm.setState("ONE");
        assertEquals(1, target.countedInt);
    }

    public function testDynamicStates():Void {

        setupSimple();

        fsm.setValue(1, ["ONE"]);
        assertEquals(0, target.propertyInt);
        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.addStates(["default2","ONE2", "TWO2"]);

        fsm.setValue(2, ["TWO2"]);
        assertEquals(1, target.propertyInt);

        fsm.setState("TWO2");
        assertEquals(1, target.propertyInt);

        fsm.setState("default");
        assertEquals(2, target.propertyInt);

        fsm.setValue(3, ["ONE", "ONE2"]);
        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.setState("ONE2");
        assertEquals(3, target.propertyInt);
    }

    public function testSetValueAfterState():Void {

        setupSimple();

        fsm.setState("ONE");
        assertEquals(0, target.propertyInt);

        fsm.setValue(1, ["ONE"]);
        assertEquals(1, target.propertyInt);
    }

    public function testForceSetValue():Void {

        setupSimple();

        fsm.setValue(1, ["ONE"]);
        fsm.setValue(1, ["TWO"]);
        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);
        target.propertyInt = 0;
        fsm.setState("default");
        fsm.setState("TWO");
        assertEquals(1, target.propertyInt);
    }

    public function testBoolComplex():Void {

        fsm.addStates(["default", "CONTRACTOR_COMPLETE", "LOCKED", "ALL_EN_ROUTE"]);
        fsm.setTarget(target);
        fsm.setTargetProperty("propertyBool");
        fsm.setDefaultValue(false);

        fsm.setValue(true, ["CONTRACTOR_COMPLETE"]);

        fsm.setState("ALL_EN_ROUTE");
        assertEquals(false, target.propertyBool);
    }

    /** Negative tests **/
    public function testTooManyStates():Void {

        var fsm:ZStateMachine<CustomTargetObject> = new ZStateMachine();

        // each set requires 3 bits
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);

        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);

        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);

        fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);

        // 30 bits used now

        var receivedError:Bool = false;
        try {

            // 33 is one too many
            fsm.addStates([new CustomTargetObject(),new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject(), new CustomTargetObject()]);
        } catch(e:Dynamic) {

            receivedError = true;
        }

        assertTrue(receivedError);
    }

    /** Test: declared is more important than assumed */
    public function testDeclaredImportance():Void {

        setupSimple();
        fsm.addStates(["default2", "ONE2", "TWO2"]);
        fsm.setValue(1, ["ONE"]);
        fsm.setState("ONE");
        assertEquals(1, target.propertyInt);

        fsm.setState("default");
        fsm.setValue(2, ["default", "default2"]);
        assertEquals(2, target.propertyInt);

        fsm.setState("ONE2");
        assertEquals(1, target.propertyInt);

        fsm.setState("default2");
        assertEquals(2, target.propertyInt);

        fsm.setState("ONE");
        assertEquals(0, target.propertyInt);
    }

}