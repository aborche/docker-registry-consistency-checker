#!/bin/sh

#set -x
registry_path="/registry"
counter=0

brokenhashdirs="${registry_path}/broken_hashdirs"
brokenhashes="${registry_path}/broken_hashes"
removefiles=""
#removefiles="--remove-files"
brokenhashdirs_archive="${brokenhashdirs}.tar"
manifestfiles="${registry_path}/manifest_files.txt"
curdate=`date "+%Y%m%d-%H%M"`

mv -v ${manifestfiles} "${manifestfiles}.${curdate}"
mv -v ${brokenhashes} "${brokenhashes}.${curdate}"
mv -v ${brokenhashdirs} "${brokenhashdirs}.${curdate}"
mv -v ${brokenhashdirs_archive} "${brokenhashdirs_archive}.${curdate}"

touch ${manifestfiles} ${brokenhashes}

# Start search json manifest files in registry
echo "Search docker manifest files in registry tree"
for searchjson in `find /registry -name "data" -path "*blobs*"`; do
	firstbyte=`head -c1 ${searchjson} | sed 's/[^{]//g'`
	if [ "X${firstbyte}" = 'X{' ]; then
		checkmanifest=`head -5 ${searchjson} | grep -c 'vnd.docker.distribution.manifest'`
		if [ "X${checkmanifest}" != "X0" ]; then
			echo ${searchjson} >> ${manifestfiles}
		fi
	fi
done

echo "Found "$(wc -l ${manifestfiles} | awk '{print $1}')" manifest files"
echo

# Search all registry parts without data and link files
echo "Search orphaned directories in registry tree"
for walker in `find /registry -name "????????????????????????????????????????????????????????????????" -type d`; do
        if [ ! -f "${walker}/data" ]; then
           if [ ! -f "${walker}/link" ]; then
                echo "${walker}" >> ${brokenhashdirs}
                echo $(basename ${walker}) >> ${brokenhashes}
                # If you need check orphaned directory contents - uncomment next block
                #echo "-----------------------------------"
                #echo "no special files at blob with hash: '"$(basename ${walker})"'"
                #echo "====== contents of ${walker} ======"; echo
                #ls -alR ${walker}
           fi
        fi
done
echo "Found "$(wc -l ${brokenhashes} | awk '{print $1}')" orphaned directories"
echo

# pack broken registry parts to archive
# If you need remove broken registry parts uncomment removefiles variable
if [ -f ${brokenhashdirs} ]; then
	echo "*************************************************"
	echo "Move orphaned directories to tar ${brokenhashdirs_archive}"
	tar -cf ${brokenhashdirs_archive} -T ${brokenhashdirs} ${removefiles}
	echo "*************************************************"
	echo
fi

# check manifest files for broken hashes
echo "Check orphaned hashes in manifest files"
for file in `cat ${manifestfiles}`; do
        found=`grep -c -f ${brokenhashes} $file`
        if [ "X${found}" != "X0" ]; then
                echo "Found ${found} broken hashes in manifest ${file}"
                manifesthash=`echo ${file} | awk -F'/' '{print $(NF-1)}'`
                        for tag in `find ${registry_path} -name ${manifesthash} -path "*/_manifests/tags/*"`; do
                                cuttag=`echo ${tag} | sed -E 's/(.*)\/repositories\/(.*)/\2/g'`
                                echo "Manifest ${manifesthash} used in:" $(echo ${cuttag} | awk -F'/' '{print $1":"$4}')
                        done
        fi
done
echo

# check all checksums in registry data files
echo "Check all data file hashes in registry tree"
for file in `find ${registry_path} -name "data" -type f`; do
	counter=$(($counter+1))
	# print count files every 100 file
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
		echo "Hash location in registry tree:"
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
		for image in `find ${registry_path} -name ${filepathsha} -path "*_layers*" | sed -E 's/(.*)\/repositories\/(.*)/\2/g' | awk -F'/' '{print $1}'`; do
			echo "Recurse search in image ${image}"
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			for mtags in `find ${registry_path} -name "link" -path "*${image}/_manifests/tags*" -path "*tags*/current*"`; do
				hashid=`cat ${mtags} | awk -F':' '{print $2}'`
				hashdatafile=`find ${registry_path} -name "data" -path "*/blobs/sha256/*/${hashid}/data"`
				if [ "X${hashdatafile}" != "X" ]; then
					datatype=`file -b ${hashdatafile}`
					if [ "X${datatype}" = "XASCII text" ]; then
						#echo ${hashid} ${hashdatafile} ${datatype}
						used=`grep ${filepathsha} ${hashdatafile}`
						if [ "X${used}" != "X" ]; then
							echo "${image}:${hashid}"
						fi
					fi
				else
					echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
					echo "ERROR: ${image}:${hashid} Not Found!"
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
