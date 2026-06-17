#This script is for deployment of RTSP sites based on the iris.json that has been copied from the main script
#This script will be pushed to the edge device for deployment
#Not to be run individually unless the very first variable is set correctly

Exp_ver_num=ExpectedVersionNumber	#DontDeleteThisComment
DevPwd=DevicePassword
Type=DeviceType
DVR_Choice1=DVRChoice1	#DontDeleteThisComment
DVR_Choice2=DVRChoice2	#DontDeleteThisComment
DVR_Choice3=DVRChoice3	#DontDeleteThisComment
DVR_Choice4=DVRChoice4	#DontDeleteThisComment

if [ $Exp_ver_num -eq 16 ]
then
	echo $DevPwd | sudo -S docker cp config_infer_primary_yolov5sP6.txt MUTHOOT_CONTAINER:/app/DS/models/BackPackHelmetDet/

fi

DVR_IP1=`cat /etc/network/interfaces | grep address | awk '{print $2}'| sed "s/\.150$/.${DVR_Choice1}/"`	#DontDeleteThisComment
DVR_IP2=`cat /etc/network/interfaces | grep address | awk '{print $2}'| sed "s/\.150$/.${DVR_Choice2}/"`	#DontDeleteThisComment
DVR_IP3=`cat /etc/network/interfaces | grep address | awk '{print $2}'| sed "s/\.150$/.${DVR_Choice3}/"`	#DontDeleteThisComment
DVR_IP4=`cat /etc/network/interfaces | grep address | awk '{print $2}'| sed "s/\.150$/.${DVR_Choice4}/"`	#DontDeleteThisComment

sed -i "s/rtsp_ip_addr1/${DVR_IP1}/g" iris.json	#DontDeleteThisComment
sed -i "s/rtsp_ip_addr2/${DVR_IP2}/g" iris.json	#DontDeleteThisComment
sed -i "s/rtsp_ip_addr3/${DVR_IP3}/g" iris.json	#DontDeleteThisComment
sed -i "s/rtsp_ip_addr4/${DVR_IP4}/g" iris.json	#DontDeleteThisComment

version_num=$(echo $DevPwd | sudo -S docker images | awk '{print $2}' | awk -F "v" '{print $2}' | awk -F "." '{print $1}' | sort -n | awk 'END{print}')
        echo "Removing previous container"
        echo $DevPwd | sudo -S docker rm -f MUTHOOT_CONTAINER
        if [[ ! $Exp_ver_num -eq $version_num ]]
        then
                echo "Pulling latest image"
               echo $DevPwd | sudo -S docker pull iwizregistry.iwizardsolutions.com:5000/muthoot:v${Exp_ver_num}.0

                echo "export display"
                export DISPLAY=:0
                echo "xhost"
                xhost +
                echo "Creating container"

		if [[ ${Type} -eq 1 ]]
		then
                	echo $DevPwd | sudo -S docker create -v /opt/nvidia/deepstream/deepstream-5.1/:/opt/nvidia/deepstream/deepstream-5.1/ -it --restart=always --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v ~/iris.json:/app/DS/iris.json -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /tmp/.X11-unix/:/tmp/.X11-unix -v /usr/local/cuda/include:/usr/local/cuda/include -v /usr/include/aarch64-linux-gnu:/usr/include/aarch64-linux-gnu -v /usr/lib/aarch64-linux-gnu/:/usr/lib/aarch64-linux-gnu --name MUTHOOT_CONTAINER iwizregistry.iwizardsolutions.com:5000/muthoot:v${Exp_ver_num}.0
		else
			echo $DevPwd | sudo docker create -v /opt/nvidia/deepstream/deepstream-5.1/:/opt/nvidia/deepstream/deepstream-5.1/ -it --restart=always --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v ~/iris.json:/app/DS/iris.json -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /tmp/.X11-unix/:/tmp/.X11-unix -v /usr/local/cuda/include:/usr/local/cuda/include -v /usr/include/aarch64-linux-gnu:/usr/include/aarch64-linux-gnu -v /usr/lib/aarch64-linux-gnu/:/usr/lib/aarch64-linux-gnu -v /usr/local/cuda:/usr/local/cuda --name MUTHOOT_CONTAINER iwizregistry.iwizardsolutions.com:5000/muthoot:v${Exp_ver_num}.0
		fi
		
        else

                echo "export display"
                export DISPLAY=:0
                echo "xhost"
                xhost +
                echo "Creating container"

                if [[ ${Type} -eq 1 ]]
                then
                        echo $DevPwd | sudo -S docker create -v /opt/nvidia/deepstream/deepstream-5.1/:/opt/nvidia/deepstream/deepstream-5.1/ -it --restart=always --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v ~/iris.json:/app/DS/iris.json -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /tmp/.X11-unix/:/tmp/.X11-unix -v /usr/local/cuda/include:/usr/local/cuda/include -v /usr/include/aarch64-linux-gnu:/usr/include/aarch64-linux-gnu -v /usr/lib/aarch64-linux-gnu/:/usr/lib/aarch64-linux-gnu --name MUTHOOT_CONTAINER iwizregistry.iwizardsolutions.com:5000/muthoot:v${version_num}.0
                else
                        echo $DevPwd | sudo docker create -v /opt/nvidia/deepstream/deepstream-5.1/:/opt/nvidia/deepstream/deepstream-5.1/ -it --restart=always --net=host --runtime nvidia -e DISPLAY=$DISPLAY -v ~/iris.json:/app/DS/iris.json -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /tmp/.X11-unix/:/tmp/.X11-unix -v /usr/local/cuda/include:/usr/local/cuda/include -v /usr/include/aarch64-linux-gnu:/usr/include/aarch64-linux-gnu -v /usr/lib/aarch64-linux-gnu/:/usr/lib/aarch64-linux-gnu -v /usr/local/cuda:/usr/local/cuda --name MUTHOOT_CONTAINER iwizregistry.iwizardsolutions.com:5000/muthoot:v${version_num}.0
                fi

        fi

        echo "Restarting container"
        echo $DevPwd | sudo -S docker restart MUTHOOT_CONTAINER
	echo "logs"
	echo $DevPwd | sudo -S docker logs -f MUTHOOT_CONTAINER --tail 50


