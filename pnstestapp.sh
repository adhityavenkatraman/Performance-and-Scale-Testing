testcount=0
inputfile=./Test-Input.json
objects=(`jq length Test-Input.json`)
objectadjust=$(($objects-1))
objarray=($(seq 0 1 $objectadjust))
for o in "${objarray[@]}"
do
	threads=(5 10)
	duration=120
	pods=2
	throughput=()
	echo "Do you wish to override default thread count (5,10), duration (120), or worker pods (2)?"
	echo "If so, make changes via the .json input file, then select 1. If not, select 2."
	select yn in Yes No; do
		case $yn in
			"Yes") inputfile=./Test-Input.json && echo "You have chosen $yn." && threads1=(`jq --argjson obj $o -r '.[$obj] | .threads1' $inputfile`) && threads2=(`jq --argjson obj $o -r '.[$obj] | .threads2' $inputfile`) && threads=($threads1 $threads2) && duration=(`jq --argjson obj $o -r '.[$obj] | .duration' $inputfile`) && pods=(`jq --argjson obj $o -r '.[$obj] | .pods' $inputfile`) && break;;
			"No") echo "You have chosen $yn." && break;;
		esac
	done
	inputfile=./Test-Input.json
	name=(`jq --argjson obj $o -r '.[$obj] | .testname' $inputfile`)
	apipath=(`jq --argjson obj $o -r '.[$obj] | .apipath' $inputfile`)
	clusterpath=(`jq --argjson obj $o -r '.[$obj] | .clusterpath' $inputfile`)
	method=(`jq --argjson obj $o -r '.[$obj] | .method' $inputfile`)
	header=(`jq --argjson obj $o -r '.[$obj] | .header' $inputfile`)
	token=(`jq --argjson obj $o -r '.[$obj] | .token' $inputfile`)
	JMX_SCRIPT=./Test-Script.jmx
	echo "API being tested: $apipath"
	for t in "${threads[@]}"
	do
		jmeter/*/bin/jmeter -n -t $JMX_SCRIPT -JTHREADS=${t} -JPATH=${apipath} -JNAME=${name} -JDURATION=${duration} -JMETHOD=${method} -JTOKEN=${token} -JHEADER=${header} -JCLUSTER=${clusterpath} -JBODY=$o&
		sleep $((${duration}/2))
		cd results
		resultfile=$(ls -t | head -n1)  #find the newest result file
		indic=(`awk -F',' -v counter=0 'NR>1 {if ($4>=400) ++counter;++samples;threshold=(samples*0.5)} END {if (counter>=threshold) print 1; else print 0} ' $resultfile`) #midway error handling
		if (($indic==1));then cd .. && break; fi
		sleep 90s
		throughput+=(`awk -F',' -v threads=$t 'NR>1 {time+=$2;++samples;realsamples=((samples));sectime=((time/1000/threads))} END { print samples/sectime}' $resultfile`)  #throughput recorder
		awk -F',' 'NR>1 {if ($2=="") print "Client Error. Verify all inputs are valid."}' $resultfile #Client Error
		indic=(`awk -F',' 'NR>1 {if ($2=="") print 1; else print 0}' $resultfile`)
		indic=(`awk -F',' -v counter=0 'NR>1 {if ($4>=400) ++counter;++samples;threshold=(samples*0.5)} END {if (counter>=threshold) print 1; else print 0} ' $resultfile`) #end error handling
		if (($indic==1));then cd .. && break; fi
		latency=(`awk -F',' -v threads=$t 'NR>1 {time+=$14;++samples;realtime=((time/threads))} END { print realtime/samples}' $resultfile`) #avg latency
		P50=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.50}'`) #50 percentile location
		P90=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.90}'`) #90 percentile location
		P95=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.95}'`) #95 percentile location
		latencyP50=(`cat $resultfile | sort -t "," -n -k 2| awk -F',' -v P=$P50  'NR==P {print $2}'`) #50 percentile calculation
		latencyP90=(`cat $resultfile | sort -t "," -n -k 2| awk -F',' -v P=$P90  'NR==P {print $2}'`) #90 percentile calculation
		latencyP95=(`cat $resultfile | sort -t "," -n -k 2| awk -F"," -v P=$P95  'NR==P {print $2}'`) #95 percentile calculation
		echo "***************************"
		echo "Summary of Run"
		echo "Mean Throughput: "${throughput[((${#throughput[@]}-1))]}" bytes/second"
		echo "Mean Latency: "$latency" ms"
		echo "Median Latency: "$latencyP50" ms"
		echo "90th Percentile Latency: "$latencyP90" ms"
		echo "95th Percentile Latency: "$latencyP95" ms"
		awk -F',' 'NR>1 {if ($4>=400) ++counter} END {if (counter>0) print "Error Count: ",counter}' $resultfile #error count
		echo "***************************"
		sleep 5s
		cd ..
		done
	if (($indic==1));then ./jmeter/*/bin/stoptest.sh; echo "Client/Server Error. Stopping Test." && exit && exit;fi
	sleep 5s
	echo "Throughput For Completed Runs: "
	for i in "${throughput[@]}"
		do echo $i" bytes/second"
		done
	echo "Comparing to previous throughput..."
	throughput1=${throughput[((${#throughput[@]}-1))]}
	throughput2=${throughput[((${#throughput[@]}-2))]}
	difference=$(bc <<< "scale=2;$throughput1-$throughput2") #comparing throughputs
	echo "Change in Throughput: "$difference" bytes/second"
	if (( $(echo "$difference < 0" |bc -l) )); then echo "Testing complete. Optimal Thread Count: " "${threads[((${#threads[@]}-2))]}";fi
	if (( $(echo "$difference > 0 && $difference < 5" |bc -l) )); then echo "Optimal Thread Count: " "${threads[((${#threads[@]}-1))]}";fi
	echo "***************************"
	while (( $(echo "$difference > 5" |bc -l) ))
	do
		lastthread=${threads[((${#threads[@]}-1))]}
		newthreadcount=$((lastthread*pods))
		if ((newthreadcount>160)); then echo "Optimal Thread Count: 160" && break; fi #limit number of runs per API
		threads=("${threads[@]}" $newthreadcount)
		jmeter/*/bin/jmeter -n -t $JMX_SCRIPT -JTHREADS=${threads[((${#threads[@]}-1))]} -JPATH=${apipath} -JNAME=${name} -JDURATION=${duration} -JMETHOD=${method} -JTOKEN=${token} -JHEADER=${header} -JCLUSTER=${cluster} -JBODY=$o&
		sleep $((${duration}/2))
		cd results
		resultfile=$(ls -t | head -n1) #find the newest result file
		indic=(`awk -F',' -v counter=0 'NR>1 {if ($4>=400) ++counter;++samples;threshold=(samples*0.5)} END {if (counter>=threshold) print 1; else print 0} ' $resultfile`) #midway error handling
		if (($indic==1));then cd .. && break; fi 
		sleep 90s
		if ((newthreadcount>100)); then sleep 40s; fi
		throughput+=(`awk -F',' -v threads=$newthreadcount 'NR>1 {time+=$2;++samples;realsamples=((samples));sectime=((time/1000/threads))} END { print samples/sectime}' $resultfile`) #throughput recorder
		awk -F',' 'NR>1 {if ($2=="") print "***Error or Script Parameters Invalid***"}' $resultfile #Client Error
		indic=(`awk -F',' 'NR>1 {if ($2=="") print 1; else print 0}' $resultfile`)
		indic=(`awk -F',' -v counter=0 'NR>1 {if ($4>=400) ++counter;++samples;threshold=(samples*0.5)} END {if (counter>=threshold) print 1; else print 0} ' $resultfile`) #end error handling
		latency=(`awk -F',' -v threads=$newthreadcount 'NR>1 {time+=$14;++samples;realtime=((time/threads))} END { print realtime/samples}' $resultfile`) #latency
		awk -F',' 'NR>1 {if ($4>=400) ++counter} END {if (counter>0) print "Error Count: ",counter}' $resultfile #error count
		if (($indic==1));then cd .. && break; fi
		P50=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.50}'`) #50 percentile location
		P90=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.90}'`) #90 percentile location
		P95=(`cat $resultfile | sort -n -k 2| awk -F',' -v counter=0 'NR>1 {counter ++} END {printf "%3.0f\n", counter*0.95}'`) #95 percentile location
		latencyP50=(`cat $resultfile | sort -t "," -n -k 2| awk -F',' -v P=$P50 'NR==P {print $14}'`) #50 percentile calculation
		latencyP90=(`cat $resultfile | sort -t "," -n -k 2| awk -F',' -v P=$P90 'NR==P {print $14}'`) #90 percentile calculation
		latencyP95=(`cat $resultfile | sort -t "," -n -k 2| awk -F',' -v P=$P95 'NR==P {print $14}'`) #90 percentile calculation
		echo "***************************"
		echo "Summary of Run"
		echo "Mean Throughput: "${throughput[((${#throughput[@]}-1))]}" bytes/second"
		echo "Mean Latency: "$latency" ms"
		echo "Median Latency: "$latencyP50" ms"
		echo "90th Percentile Latency: "$latencyP90" ms"
		echo "95th Percentile Latency: "$latencyP95" ms"
		awk -F',' 'NR>1 {if ($4>=400) ++counter} END {if (counter>0) print "Error Count: ",counter}' $resultfile #error count
		echo "***************************"
		echo "Throughput For Completed Runs: "
		for i in "${throughput[@]}"
			do echo $i" bytes/second"
			done
		echo "Comparing to previous throughput..."
		throughput1=${throughput[((${#throughput[@]}-1))]}
		throughput2=${throughput[((${#throughput[@]}-2))]}
		gap=$(bc <<< "scale=2;$throughput1-$throughput2")
		echo "Change in Throughput: "$gap" bytes/sec"
		if (( $(echo "$gap < 0" |bc -l) )); then echo "Testing complete. Optimal Thread Count: " "${threads[((${#threads[@]}-2))]}";fi  #if difference<0, use previous throughput and end test
		if (( $(echo "$gap > 0 && $gap < 5" |bc -l) )); then echo "Testing complete. Optimal Thread Count: " "${threads[((${#threads[@]}-1))]}";fi #if 5>difference>0, use newest throughput and end test
		difference=$gap
		echo "***************************"
		cd ..
		done
	if (($indic==1));then echo "Client/Server Error. Check API."; ./jmeter/*/bin/stoptest.sh; echo "End of Test" && exit && exit;fi
	((testcount++))
	if (($objects>1)); then
		echo "Testing Paused. Do you wish to proceed to the next test?"
		echo "Choose Option 1 or 2"
		select yn in Yes No ;do
			case $yn in
				"Yes") echo "You have chosen $yn." && break;;
				"No") echo "You have chosen $yn." && exit;;
			esac
		done
	fi	
	if ((testcount>objectadjust)); then exit; fi
	done