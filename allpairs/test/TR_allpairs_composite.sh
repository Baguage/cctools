#!/bin/sh

. ../../dttools/test/test_runner_common.sh

TEST_INPUT=integer.list
TEST_OUTPUT_STEP=composite_step.output
TEST_OUTPUT=composite.output
TEST_TRUTH=composites.txt
PORT_FILE=worker.port

export PATH=.:../src:../../work_queue/src:$PATH

cleanfiles()
{
        if [ -f $TEST_INPUT ]
        then
                xargs rm < $TEST_INPUT
        fi

	rm -f $TEST_INPUT
	rm -f $TEST_OUTPUT_STEP
	rm -f $TEST_OUTPUT
	rm -f $PORT_FILE
	rm -f allpairs_multicore
}

prepare()
{
	cleanfiles
	./gen_ints.sh $TEST_INPUT 20
	ln -s ../src/allpairs_multicore .
}

run()
{
	echo "starting master"
	allpairs_master -x 1 -y 1 --output-file $TEST_OUTPUT_STEP -Z $PORT_FILE $TEST_INPUT $TEST_INPUT ./divisible.sh -d all &

	echo "waiting for $PORT_FILE to be created"
	wait_for_file_creation $PORT_FILE 5

	echo "starting worker"
 	work_queue_worker localhost `cat $PORT_FILE` --timeout 10 --single-shot

	echo "checking output"
	awk '$3 ~ /^0$/{print $1}' $TEST_OUTPUT_STEP | sort -n | uniq > $TEST_OUTPUT

	diff $TEST_TRUTH $TEST_OUTPUT
	exit $?
}

clean()
{
    	cleanfiles
	exit 0
}

dispatch $@

# vim: set noexpandtab tabstop=4:
