
/proc/dd_run_tests()

	var/test_classes = typesof(/obj/test)
	for(var/class in test_classes)
		var/obj/test/tester = new class(  )
		for(var/test in tester.verbs)
			call(tester, test)()
			if (!( tester.success ))
			else
		if (!( tester.success ))
			world << "Test failed."
			return
	world << "All tests passed."
	return

/obj/test/proc/die(message)

	src.success = 0
	CRASH(message)
	return
