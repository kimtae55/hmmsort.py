#!/bin/bash

#get the groups
#get the number of highpass files
sortfile=hmmsort
sortwindow=100000
sortp=1e-10
hfiles=`ls *_highpass.[0-9]* | grep -v mat`
baseh=`echo ${hfiles} | awk -F "." '{print $1 }' | uniq`
base=`echo ${baseh} | awk -F "_" '{ for(i=1;i<NF;i++) {print $i}}' | paste -s -d "_" -`
#base=`echo ${baseh} | awk -F "_" '{print $1}'`
groups=`awk '/Active/ {print $3}' ${base}_descriptor.txt | sort | uniq`
nfiles=`echo $hfiles | awk '{print NF}'`
outfiles=''
echo $nfiles
#loop through each group
for g in $groups
do
	if [ $g -gt 0 ]
	then
		fname=`printf "%sg%.4d" $base $g`
		echo $fname
		i=1
		while [ $i -le $nfiles ]
		do
			nr=$( printf %.4d $i )
			outfile=${base}$( printf %.4d $g ).$( printf %.4d $i ).hdf5
			outfiles=${outfiles}${outfile},
			if [ ! -e $PWD/$outfile ]
			then
				jobid[$i]=`echo "touch $PWD/${outfile};cp $PWD/${baseh}.${nr} /tmp/; cd /tmp/;$HOME/Documents/matlab/hmmsort_example_ForRoger/hmm_learn_tetrode.py --sourceFile $baseh.${nr} --group $g --outFile ${outfile} ;cp /tmp/${outfile} ${PWD}/" | qsub -j y -V -N hmmLearng${g} -o $HOME/tmp/ -l mem=20G | awk '{print $3}'`
			fi
		done
		jobidstr=`echo ${jobid[*]} | sed -e 's/ /,/g'`
		#one job to gather all the results
		jobid=`echo "cd $PWD; $HOME/Documents/matlab/hmmsort_example_ForRoger/hmm_learn_tetrode.py --sourceFile ${outfiles} --combine | qsub -j y -V -N hmmGather$g -o $HOME/tmp/ -l mem=20G -l s_rt=7000 -hold_jid $jobidstr"`

		while [ $i -le $nfiles ]; do f=$fname.`printf "%.4d" $i`.mat; test -e $f|| echo "cd $PWD;touch $f; hostname; $HOME/Documents/matlab/hmmsort_example_ForRoger/run_hmm_decode.sh /Applications/MATLAB_R2010a.app/ ${sortfile}g$g $sortwindow $sortp SourceFile $baseh.$( printf "%.4d" $i ) Group $g save hdf5;test -s $f || rm $f"| qsub -j y -V -N hmmDecode$g$i -o $HOME/tmp/ -l mem=2G -l -l s_rt=7000  -hold_jid $jobid; let i=$i+1;done

	fi
done
