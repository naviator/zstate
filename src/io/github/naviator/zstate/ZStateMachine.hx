package io.github.naviator.zstate;

class ZStateMachine<T> {

    // do error checking
    private static var ERROR_CHECK:Bool = true;

    // externally visible states of constant type
    private var possibleStates:Array<Array<T>> = [];
    private var defaultState:UInt = 0;

    // target
    private var currentTarget:{};
    private var currentPropertyName:String;

    // target & values map
    private var defaultValues:Map<{}, Map<String, Dynamic>> = new Map<{}, Map<String, Dynamic>>();
    private var stateValues:Map<{}, Map<String, Map<UInt, Dynamic>>> = new Map<{}, Map<String, Map<UInt, Dynamic>>>();
    private var stateMask:Map<UInt, UInt> = new Map<UInt, UInt>();
    private var modifiedValues:Map<{}, Map<String, UInt>> = new Map<{}, Map<String, UInt>>();

    // current state
    private var currentState:UInt = 0;
    private var bitSize:Array<UInt> = [];
    private var bitsRight:Array<UInt> = [];

    // linked machines
    private var observers:Array<ZStateMachine<T>> = [];
    private var linkedMachines:Map<ZStateMachine<T>, UInt> = new Map<ZStateMachine<T>, UInt>();

    public function new() {

    }

    /**
      First state is default state.
     */
    public function addStates(states:Array<T>):Void {

        // sanity check
        if (states == null) throw "States are null.";
        if (states.length == 0) throw "States are empty.";

        // remember external values
        possibleStates.push(states);

        var bits:UInt = requiredBits(states.length);

        appendBits(bits, 0);
    }

    public function appendBits(bits:UInt, appendState:UInt):Void {

        // Update current state
        currentState = currentState << bits | appendState;

        // Update bit info
        bitSize.push(bits);
        for (i in 0...bitsRight.length) {

            bitsRight[i] += bits;
        }
        bitsRight.push(0);

        if(bitSize[0] + bitsRight[0] > 32) {

            throw "Too many states";
        }

        // Update stateValues
        for (propertyMap in stateValues) {

            for (stateMap in propertyMap) {

                for (state in stateMap.keys()) {

                    var value:Dynamic = stateMap.get(state);
                    stateMap.remove(state);
                    stateMap.set((state << bits), value);
                }
            }
        }

        // update masks
        for (state in stateMask.keys()) {

            var mask:UInt = stateMask.get(state);
            stateMask.remove(state);
            stateMask.set(state << bits, mask << bits);
        }

        // Update modifiedValues
        for (propertyMap in modifiedValues) {

            for (property in propertyMap.keys()) {

                var state:UInt = propertyMap.get(property);
                propertyMap.set(property, (state << bits));
            }
        }

        // update observers config
        for (i in 0...observers.length) {

            observers[i].updateLinkedConfig(this);
        }
    }

    private function removeBits(index:UInt):Void {

        var toRemove:UInt = bitSize[index];

        // Update current state
        var leftMask:UInt = ~((1 << (bitSize[index] + bitsRight[index])) - 1);
        var rightMask:UInt = ((1 << bitsRight[index]) - 1);

        currentState = ((currentState & leftMask) >> toRemove) | (currentState & rightMask);

        // Update bit info
        bitSize.splice(index, 1);
        for (i in 0...index) {

            bitsRight[i] -= toRemove;
        }
        bitsRight.splice(index, 1);

        var update:Bool = false;

        // Update stateValues
        for (propertyMap in stateValues) {

            for (stateMap in propertyMap) {

                for (state in stateMap.keys()) {

                    var newState = ((state & leftMask) >> toRemove) | (state & rightMask);

                    if(state != newState) {
                        update = true;
                        var value:Dynamic = stateMap.get(state);
                        stateMap.remove(state);
                        stateMap.set(newState, value);
                    }
                }
            }
        }

        for (state in stateMask.keys()) {

            var mask:UInt = stateMask.get(state);

            stateMask.set(((state & leftMask) >> toRemove) | (state & rightMask),
                ((mask & leftMask) >> toRemove) | (mask & rightMask));
        }

        // Update modifiedValues
        for (propertyMap in modifiedValues) {

            for (property in propertyMap.keys()) {

                var state:UInt = propertyMap.get(property);
                state = ((state & leftMask) >> toRemove) | (state & rightMask);
                var newState:UInt = ((state & leftMask) >> toRemove) | (state & rightMask);

                if (state != newState) {
                    update = true;
                    propertyMap.set(property, newState);
                }
            }
        }

        // update observers config
        for (i in 0...observers.length) {

            observers[i].updateLinkedConfig(this);
        }

        if (update) {

            updateValues();
        }
    }

    // LINKED MACHINES
    public function addMachine(machine:ZStateMachine<T>):Void {

        if(machine.observers.indexOf(machine) != -1) return;

        machine.observers.push(this);

        linkedMachines.set(machine, possibleStates.length);

        appendBits(machine.bitSize[0] + machine.bitsRight[0], machine.currentState);
    }

    public function removeMachine(machine:ZStateMachine<T>):Void {

        var observerIdx:Int = machine.observers.indexOf(this);

        if(observerIdx == -1) return;

        machine.observers.splice(observerIdx, 1);

        var machineIndex:UInt = linkedMachines.get(machine);

        linkedMachines.remove(machine);

        removeBits(machineIndex);
    }

    public function removeStates(states:Array<T>):Void {

        // sanity check
        if (states == null) throw "States are null.";
        if (states.length == 0) throw "States are empty.";

        // remember external values
        var statesIdx:Int = possibleStates.indexOf(states);

        if(statesIdx == -1) return;

        possibleStates.splice(statesIdx, 1);

        removeBits(statesIdx);
    }

    public function dispose():Void {

        var count:UInt = observers.length;

        for (i in 1...count) {

            observers[count - i].removeMachine(this);
        }

        observers = null;
        linkedMachines = null;

        // the rest is presumed to be garbage collected
    }

    private function updateLinkedState(machine:ZStateMachine<T>):Void {

        var index:Int = linkedMachines.get(machine);

        var leftMask:UInt = ~((1 << (bitSize[index] + bitsRight[index])) - 1);
        var rightMask:UInt = ((1 << bitsRight[index]) - 1);

        var newState:UInt = (currentState & (leftMask | rightMask)) | (machine.currentState << bitsRight[index]);

        if (newState != currentState) {

            currentState = newState;

            updateValues();
        }
    }

    private function updateLinkedConfig(machine:ZStateMachine<T>):Void {

        var index:Int = linkedMachines.get(machine);

        var diff:Int = machine.bitSize[0] + machine.bitsRight[0] - bitSize[index];

        if (diff != 0) {

            var leftMask:UInt = ~((1 << (bitSize[index] + bitsRight[index])) - 1);
            var rightMask:UInt = ((1 << bitsRight[index]) - 1);

            if(diff > 0) {

                currentState = ((currentState & leftMask) << diff) | (currentState & rightMask);
            } else {

                currentState = ((currentState & leftMask) >> (-diff)) | (currentState & rightMask);
            }

            bitSize[index] += diff;

            for(i in 0...index) {

                bitsRight[i] += diff;
            }

            // Update stateValues
            for (propertyMap in stateValues) {

                for (stateMap in propertyMap) {

                    for (state in stateMap.keys()) {

                        var value:Dynamic = stateMap.get(state);
                        stateMap.remove(state);

                        if(diff > 0) {

                            state = ((state & leftMask) << diff) | (state & rightMask);
                        } else {

                            state = ((state & leftMask) >> (-diff)) | (state & rightMask);
                        }
                        stateMap.set(state, value);
                    }
                }
            }

            // update masks
            for (state in stateMask.keys()) {

                var mask:UInt = stateMask.get(state);
                stateMask.remove(state);

                if(diff > 0) {

                    state = ((state & leftMask) << diff) | (state & rightMask);
                    mask = ((mask & leftMask) << diff) | (mask & rightMask);
                } else {

                    state = ((state & leftMask) >> (-diff)) | (state & rightMask);
                    mask = ((mask & leftMask) >> (-diff)) | (mask & rightMask);
                }
            }

            // Update modifiedValues
            for (propertyMap in modifiedValues) {

                for (property in propertyMap.keys()) {

                    var state:UInt = propertyMap.get(property);

                    if(diff > 0) {

                        state = ((state & leftMask) << diff) | (state & rightMask);
                    } else {

                        state = ((state & leftMask) >> (-diff)) | (state & rightMask);
                    }

                    propertyMap.set(property, state);
                }
            }
        }
    }

    // SET TARGET
    /**
     *  Set target:
     * - target object
     * - property name
     * - default value
     * - state values.
    */
    public function setTarget(target:{}):Void {

        currentTarget = target;
    }

    public function setTargetProperty(propertyName:String):Void {

        currentPropertyName = propertyName;
    }

    public function setDefaultValue(value:Dynamic):Void {

        if (currentTarget == null) throw "Target must be set.";
        if (currentPropertyName == null) throw "Property name must be set.";

        if (!defaultValues.exists(currentTarget)) {

            defaultValues.set(currentTarget, new Map<String, Dynamic>());
        }

        var properties:Map<String, Dynamic> = defaultValues.get(currentTarget);

        properties.set(currentPropertyName, value);
    }

    // SET VALUE & STATE
    public function setValue(value:Dynamic, states:Array<T>):Void {

        if (ERROR_CHECK) {

            if (currentTarget == null) throw "Target must be set.";
            if (currentPropertyName == null) throw "Property name must be set.";
        }

        if (!stateValues.exists(currentTarget)) {
            stateValues.set(currentTarget, new Map<String, Map<UInt, Dynamic>>());
        }

        var properties:Map<String, Map<UInt, Dynamic>> = stateValues.get(currentTarget);

        if (!properties.exists(currentPropertyName)) {
            properties.set(currentPropertyName, new Map<UInt, Dynamic>());
        }

        var propertyStates:Map<UInt, Dynamic> = properties.get(currentPropertyName);

        var stateValue:UInt = getStatesValue(states);

        if(!stateMask.exists(stateValue)) {
            stateMask.set(stateValue, getMask(stateValue));
        }

        propertyStates.set(stateValue, value);

        if(stateApplies(stateValue)) {

            updateValues();
        }
    }

    inline private function getMask(stateValue:UInt):UInt {

        var result:UInt = 0;

        for (i in 0...bitSize.length) {

            var mask:UInt = (cast(Math.pow(2, bitSize[i]), UInt) - 1) << bitsRight[i];

            if(stateValue & mask > 0) {

                result |= mask;
            }
        }

        return result;
    }

    public function setState(newState:T):Void {

        var group:Int = getStateGroup(newState);

        if(ERROR_CHECK) {

            if(group == -1) throw "New state unknown.";
        }

        // Calculate new state
        var mask:UInt = cast(Math.pow(2, bitSize[group]) - 1, UInt) << bitsRight[group];
        var stateValue:UInt = getStateValue(newState);
        var newStateValue:UInt = (currentState & ~mask) | stateValue;

        if (newStateValue != currentState) {

            currentState = newStateValue;

            updateValues();
        }
    }

    // UPDATE
    private function updateValues():Void {

        // update observers
        for (i in 0...observers.length) {

            observers[i].updateLinkedState(this);
        }

        // update values
        for (target in stateValues.keys()) {

            var properties:Map<String, Map<UInt, Dynamic>> = stateValues.get(target);

            for (property in properties.keys()) {

                // get previous state
                var previousPropertyState:UInt = getStateFor(target, property);
                var modified:Bool = previousPropertyState != defaultState;
                var newPropertyState:UInt = defaultState;

                // target, property, state available at this point
                var states:Map<UInt, Dynamic> = properties.get(property);
                for (stateValue in states.keys()) {

                    // compare this state with the best one so far
                    if (stateApplies(stateValue) && stateValue >= newPropertyState) {

                        newPropertyState = stateValue;
                    }
                }

                // if changed
                if (newPropertyState != previousPropertyState) {

                    if (newPropertyState == defaultState) {

                        // restore default value
                        if (modified) {

                            // remove from modified list
                            modifiedValues.get(target).remove(property);
                        }

                        // set value
                        var propertyMap:Map<String, Dynamic> = defaultValues.get(target);
                        if (propertyMap != null && propertyMap.exists(property)) {

                            var defaultValue:Dynamic = propertyMap.get(property);

                            Reflect.setProperty(target, property, defaultValue);
                        }

                        else if (ERROR_CHECK) {

                            throw "Default property missing for " + property + " on target " + target;
                        }
                    } else {

                        // add modified property
                        if (!modifiedValues.exists(target)) {
                            modifiedValues.set(target, new Map<String, UInt>());
                        }

                        var targets:Map<String, UInt> = modifiedValues.get(target);

                        targets.set(property, newPropertyState);

                        // set value
                        Reflect.setProperty(target, property, states.get(newPropertyState));
                    }
                }
            }
        }
    }

    // HELPER METHODS
    inline private function getStateGroup(state:T):Int {

        var result:Int = -1;

        for (i in 0...possibleStates.length) {

            var states:Array<T> = possibleStates[i];

            if(states.indexOf(state) >= 0) {

                result = i;
                break;
            }
        }

        return result;
    }

    inline private function requiredBits(valuesCount:Int):UInt {

        var exp:UInt = 0;
        var maxValues:Int = 1;

        if (valuesCount <= 2) exp = 1;
        else if (valuesCount <= 4) exp = 2;
        else if (valuesCount <= 8) exp = 3;
        else if (valuesCount <= 16) exp = 4;
        else if (valuesCount <= 32) exp = 5;
        else {

            maxValues *= 2;
            exp++;

            while (valuesCount >= maxValues) {

                maxValues *= 2;
                exp++;
            }
        }

        return exp;
    }

    inline private function getStateFor(target:Dynamic, property:String):UInt {

        var result:UInt = 0;

        var properties:Map<String, UInt> = modifiedValues.get(target);

        if (properties != null && properties.exists(property)) {

            result = properties.get(property);
        }

        return result;
    }

    inline private function stateApplies(statesValue:UInt):Bool {

        return currentState & stateMask.get(statesValue) == statesValue;
    }

    inline private function getStatesValue(states:Array<T>):UInt {

        var result:UInt = 0;

        for (i in 0...states.length) {

            result = result | getStateValue(states[i]);
        }

        return result;
    }

    inline private function getStateValue(state:T):UInt {

        var result:UInt = 0;
        var found:Bool = false;

        for (j in 0...possibleStates.length) {

            var allStates:Array<T> = possibleStates[j];

            for (k in 0...allStates.length) {

                var candidate:T = allStates[k];

                if (candidate == state) {

                    result = k << bitsRight[j];

                    found = true;

                    break;
                }
            }

            if(found) {

                break;
            }
        }

        if (!found) {

            var machines:Iterator<ZStateMachine<T>> = linkedMachines.keys();

            while (machines.hasNext()) {

                var machine:ZStateMachine<T> = machines.next();

                var group:Int = machine.getStateGroup(state);

                if (group >= 0) {

                    result = machine.getStateValue(state);
                    group = linkedMachines.get(machine);
                    result = result << bitsRight[group];
                    break;
                }
            }
        }

        return result;
    }
}
