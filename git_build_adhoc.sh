#!/bin/bash

echo "Louise Build Test"
 
if [ "$2" == "" ]; then
    	echo usage: $0 \<Branch\> \<RState\>
    	exit -1
else
	versionProperties=install/version.properties
	theDate=\#$(date +"%c")
	module=$1
	branch=$2
	workspace=$3

	echo $workspace
fi
function getProductNumber {
        product=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $3}'`
}

function setRstate {
        revision=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $4}'`
	
	if git tag | grep $product-$revision; then
        	rstate=`git tag | grep ${product}-${revision} | tail -1 | sed s/.*-// | perl -nle 'sub nxt{$_=shift;$l=length$_;sprintf"%0${l}d",++$_}print $1.nxt($2) if/^(.*?)(\d+$)/';`
        else
		ammendment_level=01
	        rstate=$revision$ammendment_level
	fi
	mv src/resources/meta-data.xml src/resources/meta-data.${rstate}.xml
	echo "Building rstate:$rstate"
}

function Arm104nexusDeploy {
	
	RepoURL=https://arm104-eiffel004.lmera.ericsson.se:8443/nexus/content/repositories/assure-releases
	GroupId=com.ericsson.eniq
	ArtifactId=LTE-Ad-Hoc
	zipName=Ericsson-network-analytics-AdHoc-LTE
	
	echo "****"	
	echo "Deploying the zip /$zipName-15.0-A.zip as ${ArtifactId}.zip to Nexus...."
        mv target/$zipName-*.zip target/${ArtifactId}.zip
	echo "****"	

  	mvn deploy:deploy-file \
	        	-Durl=${RepoURL} \
		        -DrepositoryId=assure-releases \
		        -DgroupId=${GroupId} \
		        -Dversion=${rstate} \
		        -DartifactId=${ArtifactId} \
		        -Dfile=target/${ArtifactId}.zip
}

getProductNumber
setRstate
git checkout $branch
git pull

echo "egallou Test ......... Script executed from: ${PWD}"

echo "egallou Test ......... Contents of directory"
ls -d */

cd adhoc

echo "egallou Test ......... working directory now: ${PWD}"

#add maven command here
mvn package


rsp=$?

if [ $rsp == 0 ]; then
  git tag $product-$rstate
  git pull origin $branch
  git push --tag origin $branch
  Arm104nexusDeploy
fi

exit $rsp
