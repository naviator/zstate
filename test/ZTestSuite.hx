package ;

import haxe.unit.TestRunner;
class ZTestSuite {

    public static function main ()
    {
        var runner = new TestRunner();

        // Register all our test cases
        runner.add(new ZBasicStateTest());
        runner.add(new ZLinkedStateTest());

        // Run them and and exit with the right return code
        var success = runner.run();
    }
}
