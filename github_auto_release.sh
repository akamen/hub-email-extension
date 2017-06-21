###############################################################################################################################################################################################
## BlackDuck Github Auto Release 
## v0.0.3
##
## Purpose: Automatically release build artifacts to GitHub on stable, non-SNAPSHOT, project builds. Uses the following project: https://github.com/aktau/github-release. 
##
## How to: to run, ./github_auto_release.sh <parameters>
## Parameters:
##		-b|--buildTool 						required: specify build tool (maven or gradle for now)
##		-g|--gitToken          				required: specify personal github authentication token (this will not be required in final release)
##		-f|--artifactFile        			optional: specify file path to project's artifact file (if build artifact is not standard, user can specify to make sure it is released) <CANNOT SPECIFY BOTH A DIRECTORY AND FILE>
##		-d|--artifactDirectory 				optional: specify a directory to be zipped and released <CANNOT SPECIFY BOTH A DIRECTORY AND FILE>
##		-m|--releaseDesc         			optional: add description for release to github
##		-o|--organization		   			optional: the name of the organization under which the repo is located (default is blackducksoftware)
##		-ev|--executableVersion   			optional: which version of the GitHub-Release executable to be used (default is v0.7.2 because that is the version this script is being tested with)
##		-ep|--executablePath 	   			optional: where on the user's machine the GitHub-Release executable will live (defualt is set to ~/temp/blackducksoftware)
################################################################################################################################################################################################

BLUE='\033[0;34m'
NC='\033[0m'
YELLOW='\033[0;33m'
RED='\033[0;31m' 
GREEN='\033[0;32m' 

BUILD_TOOL=""
GITHUB_TOKEN=""
ARTIFACT_FILE=""
ARTIFACT_DIRECTORY=""
DESC="GitHub Autorelease"
EXECUTABLE_VERSION="v0.7.2" #default to this because this is what script has been tested/based on
EXECUTABLE_PATH=~/temp/blackducksoftware
ORGANIZATION="patrickwilliamconway" #final version this will be blackducksoftware

echo -e " --- ${GREEN}Starting GitHub Autorelease Script${NC} --- " 

####################################	PARSING INPUT PARAMETERS 		#####################################
args=("$@")
for ((i=0; i<$#; i=i+2));
do
    FLAG=${args[$i]}
    VAL=${args[$i+1]}
    if [[ "$VAL" == -* ]] || [[ "$VAL" == --* ]] || [[ -z "$VAL" ]]; then #should this just be a check for an empty string, or should it be like it is?
    	if [[ "$FLAG" != "-h" ]] && [[ "$FLAG" != "--help" ]]; then
	    	echo -e " --- ${RED}ERROR: Incorrectly formatted VAL input. Flag/Value pair < $FLAG, $VAL > causing error.${NC} --- "
	    	exit 1
    	fi
    fi

    case $FLAG in
        -b|--buildTool) 
            BUILD_TOOL=$VAL
            ;;
        -d|artifactDirectory)
			ARTIFACT_DIRECTORY=$VAL
			echo -e "${BLUE}artifact directory:${NC} $ARTIFACT_DIRECTORY. Script will look for this exact directory. If it exists, it will zip and attach all contents to release."
			;;
        -f|--artifactFile)
            ARTIFACT_FILE=$VAL
            echo -e "${BLUE}artifact file path:${NC} $ARTIFACT_FILE. Script will look for this exact build artifact."
            ;;
        -g|--gitToken)
            export GITHUB_TOKEN=$VAL #this will exist within jenkins
            ;;
        -m|--releaseDesc) #rename
            DESCRIPTION=$VAL
            ;;
       	-o|--organization)
			ORGANIZATION=$VAL
			echo -e "${BLUE}organization that owns repository:${NC} $ORGANIZATION"
			;;
        -ev|--executableVersion)
			EXECUTABLE_VERSION=$VAL
			echo -e "${BLUE}github-release executable version:${NC} $EXECUTABLE_VERSION"
			;;
		-ep|--executablePath)
			EXECUTABLE_PATH=$VAL
			echo -e "${BLUE}github-release excutable location path:${NC} $EXECUTABLE_PATH"
			;;
        -h|--help) 
            echo -e "${BLUE}HELP MENU - options${NC}"
			echo -e "-b|--buildTool 					${RED}required:${NC} specify build tool"
			echo -e "-g|--gitToken          				${RED}required:${NC} specify personal github authentication token"
			echo -e "-f|--artifactFile        			${YELLOW}optional:${NC} specify file path to project's artifact file"
			echo -e "-d|--artifactDirectory 				${YELLOW}optional:${NC} specify a directory to be zipped and released <CANNOT SPECIFY BOTH A DIRECTORY AND FILE>"
			echo -e "-m|--releaseDesc         			${YELLOW}optional:${NC} add description for release to github" 
			echo -e "-o|--organization		   		${YELLOW}optional:${NC} the name of the organization under which the repo is located (default is blackducksoftware)"
			echo -e "-ev|--executableVersion   			${YELLOW}optional:${NC} which version of the GitHub-Release executable to be used (default is v0.7.2)"
			echo -e "-ep|--executablePath 	   			${YELLOW}optional:${NC} where on the user's machine the GitHub-Release executable will live (defualt is ~/temp/blackducksoftware)"
			exit 1
			;;
		*)
			echo -e " --- ${RED}ERROR: unrecognized flag variable in Flag/Value pair:${NC} < $FLAG, $VAL > --- "
			exit 1
			;;
    esac
done

if [ -z "$BUILD_TOOL" ]; then 
    echo -e " --- ${RED}ERROR: BUILD_TOOL ($BUILD_TOOL) (-b|--buildTool)${NC} --- "
    exit 1
elif ! [ -z "$ARTIFACT_DIRECTORY" ] && ! [ -z "$ARTIFACT_FILE"]; then
	echo -e " --- ${RED}ERROR: ARTIFACT_DIRECTORY ($ARTIFACT_DIRECTORY) and ARTIFACT_FILE ($ARTIFACT_FILE) cannot both be specified${NC} --- "
	exit 1
fi

shopt -s nocasematch
if [[ "$BUILD_TOOL" == "maven" ]]; then 
	RELEASE_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -e 'Building')
	RELEASE_VERSION=$(echo $RELEASE_VERSION | awk {'print $NF'})
elif [[ "$BUILD_TOOL" == "gradle" ]]; then
	RELEASE_VERSION=$(./gradlew properties | grep ^version:)
	RELEASE_VERSION=${RELEASE_VERSION##* }
else 
	echo -e " --- ${RED}ERROR: build tool must either be maven or gradle (you entered: $BUILD_TOOL)${NC} --- "
	exit 1
fi
shopt -u nocasematch


if [[ "$RELEASE_VERSION" =~ [0-9]+[.][0-9]+[.][0-9]+ ]] && [[ "$RELEASE_VERSION" != *"SNAPSHOT"* ]]; then #regex matches x.y.z where x,y,z are integers

	####################################	FINDING GITHUB-RELEASE EXECUTABLE FILE 		#####################################
	if [ ! -d "$EXECUTABLE_PATH" ]; then
		mkdir -p "$EXECUTABLE_PATH"
		echo "$EXECUTABLE_PATH was just created"
	fi


	EXECUTABLE_PATH_EXISTS=$(find $EXECUTABLE_PATH -name "github-release")
	if [ -z "$EXECUTABLE_PATH_EXISTS" ]; then 
		echo -e " --- ${BLUE}github-release executable does not already exist on this machine${NC} --- "
		GO=$(which go) #need to accomodate the windows equivalent
		if [ -z "$GO" ]; then #if go isn't installed on the machine, pull binaries from releases directly
			OS_TYPE=$(uname -a | awk {'print $1'}) 
			OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]') #convert OSTYPE to lower case
			
			# WGET=$(which wget)
			# if [ -z $WGET ]; then
			# 	if [ "$OS_TYPE" == "darwin" ]; then

			# 	elif [ "$OS_TYPE" == "linux" ]; then
			# 		echo "intsall wget for linux"
			# 	fi
			# fi

			if [[ "$OS_TYPE" == "darwin" ]] || [[ "$OS_TYPE" == "linux" ]]; then
				echo -e " --- ${BLUE}Getting necessary github-release executable from github.com/aktau/github-release${NC} --- "
				curl -OL "https://github.com/aktau/github-release/releases/download/$EXECUTABLE_VERSION/$OS_TYPE-amd64-github-release.tar.bz2" 
				
				echo " "
				echo $EXECUTABLE_PATH
				ls $EXECUTABLE_PATH
				echo "pwd: $PWD"
				ls $PWD

				tar -zxvf $EXECUTABLE_PATH/"$OS_TYPE"-amd64-github-release.tar.bz2
				
				echo " "
				ls $EXECUTABLE_PATH
				echo "pwd: $PWD"
				
				echo " "
				ls $EXECUTABLE_PATH
				echo "pwd: $PWD"
				

				echo " --- github-release executable now located in $EXECUTABLE_PATH --- "
			elif [[ "$OS_TYPE" == "mingw" ]]; then #windows section needs to be worked on
				curl -o $EXECUTABLE_PATH/windows-amd64-github-release.zip "https://github.com/aktau/github-release/releases/download/v0.7.2/windows-amd64-github-release.zip" 
				unzip $EXECUTABLE_PATH/windows-amd64-github-release.zip -d $EXECUTABLE_PATH/
				mv $EXECUTABLE_PATH/bin/windows/amd64/github-release.exe $EXECUTABLE_PATH/
				rm -R $EXECUTABLE_PATH/bin $EXECUTABLE_PATH/windows-amd64-github-release.zip
				echo " --- github-release executable now located in $EXECUTABLE_PATH --- "
			fi
		else
			echo -e " --- ${BLUE}Getting executable via go command: go get github.com/aktau/github-release${NC} --- "
			go get github.com/aktau/github-release
			if [[ -z "$GOPATH" ]]; then
				mv ~/go/bin/github-release $EXECUTABLE_PATH 
				rm -rf ~/go/pkg/darwin_amd64
				rm -rf ~/go/src/github.com/aktau ~/go/src/github.com/dustin ~/go/src/github.com/tomnomnom ~/go/src/github.com/voxelbrain
			else
				mv "$GOPATH"/bin/github-release $EXECUTABLE_PATH 
				rm -rf "$GOPATH"/pkg/darwin_amd64
				rm -rf "$GOPATH"/src/github.com/aktau "$GOPATH"/src/github.com/dustin "$GOPATH"/src/github.com/tomnomnom "$GOPATH"/src/github.com/voxelbrain
			fi
			echo " --- github-release executable now located in $EXECUTABLE_PATH --- "	
		fi
	fi


	####################################	USING INPUT AND EXECUTABLE FILE TO RELEASE/POST TO GITHUB 		#####################################
	REPO_NAME=$(git remote -v)
	REPO_NAME=$(echo $REPO_NAME | awk '{print $2}')
	REPO_NAME=${REPO_NAME##*/}
	REPO_NAME=${REPO_NAME%.*}
	
	echo -e "${BLUE}Build Tool:${NC} $BUILD_TOOL"
	echo -e "${BLUE}Release Description specified:${NC} $DESC"
	echo -e "${BLUE}Repository Name:${NC} $REPO_NAME"
	echo -e "${BLUE}Release Version:${NC} $RELEASE_VERSION"

	RELEASE_COMMAND_OUTPUT=$(exec $EXECUTABLE_PATH/github-release release --user $ORGANIZATION --repo $REPO_NAME --tag $RELEASE_VERSION --name $RELEASE_VERSION --description "$DESC" 2>&1)
	
	if [ -z "$RELEASE_COMMAND_OUTPUT" ]; then
		echo -e " --- ${GREEN}Release posted to GitHub${NC} --- "

		if ! [ -z "$ARTIFACT_FILE" ]; then 
			ARTIFACT_FILE=$(find . -iname "$ARTIFACT_FILE")
			ARTIFACT_NAME=$(basename "$ARTIFACT_FILE")
			echo -e "${BLUE}Artifact File:${NC} $ARTIFACT_FILE"
			echo -e "${BLUE}Artifact Name:${NC} $ARTIFACT_NAME"
			POST_COMMAND_OUTPUT=$(exec $EXECUTABLE_PATH/github-release upload --user $ORGANIZATION --repo $REPO_NAME --tag $RELEASE_VERSION --name $ARTIFACT_NAME --file "$ARTIFACT_FILE" 2>&1)	
		elif ! [ -z "$ARTIFACT_DIRECTORY" ]; then
			TEMP=$ARTIFACT_DIRECTORY
		  	ARTIFACT_DIRECTORY=$(find . -iname "$ARTIFACT_DIRECTORY")
		  	ARTIFACT_NAME="$REPO_NAME"-"$RELEASE_VERSION"_"$TEMP"Dir.zip
		  	zip -r "$ARTIFACT_NAME".zip $ARTIFACT_DIRECTORY 
		  	POST_COMMAND_OUTPUT=$(exec $EXECUTABLE_PATH/github-release upload --user $ORGANIZATION --repo $REPO_NAME --tag $RELEASE_VERSION --name $ARTIFACT_NAME --file "$ARTIFACT_NAME.zip" 2>&1)	
		else 
			ARTIFACT_FILE=$(find . -iname "$REPO_NAME-$RELEASE_VERSION.zip")
		
			if [ -z "$ARTIFACT_FILE" ]; then #if .zip doesn't exist, look for .tar
				ARTIFACT_FILE=$(find . -iname "$REPO_NAME-$RELEASE_VERSION.tar")
			fi

			if ! [ -z "$ARTIFACT_FILE" ]; then
				ARTIFACT_NAME=$(basename "$ARTIFACT_FILE")
				echo -e "${BLUE}Artifact ARTIFACT_FILE:${NC} $ARTIFACT_FILE"
				echo -e "${BLUE}Artifact Name:${NC} $ARTIFACT_NAME" 
				POST_COMMAND_OUTPUT=$(exec $EXECUTABLE_PATH/github-release upload --user $ORGANIZATION --repo $REPO_NAME --tag $RELEASE_VERSION --name $ARTIFACT_NAME --file "$ARTIFACT_FILE" 2>&1)
			else 
				echo -e " --- ${YELLOW}No artifact files found. No artifact will be attached to release.${NC} --- "
				POST_COMMAND_OUTPUT="null"
			fi		
		fi

		if [ -z "$POST_COMMAND_OUTPUT" ]; then
			echo -e " --- ${GREEN}Artifacts attached to release on GitHub${NC} --- "
			echo -e " --- ${GREEN}GitHub Autorelease Script Ending${NC} --- "
		elif [[ "$POST_COMMAND_OUTPUT" == "null" ]]; then
			echo -e " --- ${GREEN}GitHub Autorelease Script Ending${NC} --- "
			exit 1
		else
			echo -e " --- ${RED}$POST_COMMAND_OUTPUT${NC} --- "
			exit 1
		fi

	else 
		echo -e " --- ${RED}$RELEASE_COMMAND_OUTPUT${NC} --- "
		exit 1
	fi 

else
	echo -e " --- ${YELLOW}SNAPSHOT found in version name OR version name doesn't follow convention x.y.z where x,y,z are integers separated by .'s - ($RELEASE_VERSION) - NOT releasing to GitHub${NC} --- "
fi

