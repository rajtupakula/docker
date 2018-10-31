#!/bin/bash
 #set -x
imageslist=$(docker ps --format "{{.Image}}")
echo "list of available images"
echo "${imageslist}"
echo "################################"
DATAPATH='/home/ec2-user/docker/updater/data'

if [ ! -d "${DATAPATH}" ]; then
        mkdir "${DATAPATH}";
fi
IMAGES=$(docker ps --format "{{.Image}}")
for IMAGE in $IMAGES; do
        ORIGIMAGE=${IMAGE}
        if [[ "$IMAGE" != *\/* ]]; then
                IMAGE=library/${IMAGE}
        fi
        IMAGE=${IMAGE%%:*}
        echo "Checking ${IMAGE}"
        PARSED=${IMAGE//\//.}
	#echo "{$PARSED}"
        if [ ! -f "${DATAPATH}/${PARSED}" ]; then
                # File doesn't exist yet, make baseline
                echo "Setting baseline for ${IMAGE}"
               # curl -s "https://registry.hub.docker.com/v2/repositories/${IMAGE}/tags/" > "${DATAPATH}/${PARSED}"
               docker images ${IMAGE} | awk '{if(NR>1) print $2}' > "${DATAPATH}/${PARSED}"
        else
                # File does exist, do a compare
                #NEW=$(curl -s "https://registry.hub.docker.com/v2/repositories/${IMAGE}/tags/")
                curl -s "https://registry.hub.docker.com/v2/repositories/${IMAGE}/tags/"|jq '.results[]["name"]'| sed 's/"//g'  > "${DATAPATH}/${PARSED}.hub"
	        NEW=$(cat "${DATAPATH}/${PARSED}.hub")
                OLD=$(cat "${DATAPATH}/${PARSED}")
                if [[ "${NEW}" == "${OLD}" ]]; then
                        echo "Image ${IMAGE} is up to date";
                else
                       # echo ${NEW} > "${DATAPATH}/${PARSED}"
                        echo "Image ${IMAGE} needs to be updated"
		echo "missing tags for this image ${IMAGE} are:"
                diff ${DATAPATH}/${PARSED}.hub ${DATAPATH}/${PARSED} | grep "<" | sed 's/^<//g'
		echo "********************************************************************************"
		echo "The latest version avaialable for this  image ${IMAGE}:"
		head -1 ${DATAPATH}/${PARSED}.hub
		current_version=$(head -1 ${DATAPATH}/${PARSED}.hub)
		echo "****************************************************************************"
		echo "current running image tag is:"
		head -1 ${DATAPATH}/${PARSED}
		older_version=$(head -1 ${DATAPATH}/${PARSED})
		echo "${olderversion}"	
		echo " "
		container-diff diff ${IMAGE}:${current_version} ${IMAGE}:${older_version} --type=apt --type=node
		echo "*****************************************************************************************************"
		echo " "
		echo " "

                fi

        fi
done;
