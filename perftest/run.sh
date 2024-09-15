#!/usr/bin/bash

for i in $(seq 1 10);
do
	/usr/bin/time -v perf stat  -B -e cache-references,cache-misses,cycles,instructions,branches,faults,migrations,L1-dcache-loads,L1-dcache-load-misses,ic_tag_hit_miss.all_instruction_cache_accesses ./perftest
done
