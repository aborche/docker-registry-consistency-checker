#!/bin/sh

#set -x
registry_path="/registry"
counter=0
for file in `find ${registry_path} -name "data" -type f`; do
	counter=$(($counter+1))
	countermod=$(($counter%100))
	echo -n '.'
	if [ $countermod = 0 ]; then
		echo -n ${counter}
	fi
	getsha256=`sha256sum ${file}`
	filesha256=`echo ${getsha256} | awk -F' ' '{print $1}'`
	filepath=`echo ${getsha256} | awk -F' ' '{print $2}'`
	filepathsha=`basename $(echo ${filepath} |sed -E 's/\/data\$//g')`
	if [ 'X'${filesha256} != 'X'${filepathsha} ]; then
		echo
		echo "=================================================================="
		echo "[ERROR] Hash missmatch for: ${filepath}"
		echo "[ERROR] Original value: ${filepathsha}"
		echo "[ERROR] Computed value: ${filesha256}"
		echo
		echo "Hash used in:"
		find ${registry_path} -name ${filepathsha}
		echo "------------------------------------------------------------------"
		echo "Tags affected:"
		find ${registry_path} -name ${filepathsha} -path "*_manifests/tags*" | sed -E 's/(.*)\/repositories\/(.*)/\2/g' | awk -F'/' '{print $1":"$4}'
		echo "------------------------------------------------------------------"
		echo "Layers affected:"
		find ${registry_path} -name ${filepathsha} -path "*_layers*" | sed -E 's/(.*)\/repositories\/(.*)/\2/g' | awk -F'/' '{print $1":"$4}'
		echo "------------------------------------------------------------------"
		echo "Manifests affected:"
		echo
		for manifest in `find ${registry_path} -name ${filepathsha} -path "*_layers*" | sed -E 's/(.*)\/repositories\/(.*)/\2/g' | awk -F'/' '{print $1}'`; do
			echo "Recurse search in repo ${manifest}"
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			for mtags in `find ${registry_path} -name "link" -path "*${manifest}/_manifests/tags*" -path "*tags*/current*"`; do
				hashid=`cat ${mtags} | awk -F':' '{print $2}'`
				hashdatafile=`find ${registry_path} -name "data" -path "*/blobs/sha256/*/${hashid}/data"`
				if [ "X${hashdatafile}" != "X" ]; then
					datatype=`file -b ${hashdatafile}`
					if [ "X${datatype}" = "XASCII text" ]; then
						used=`grep ${filepathsha} ${hashdatafile}`
						if [ "X${used}" != "X" ]; then
							echo "${manifest}:${hashid}"
						fi
					fi
				else
					echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
					echo "ERROR: ${manifest}:${hashid} Not Found!"
					echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
				fi
			done
			echo
		done
		echo "=================================================================="
		echo
	fi
done
echo
