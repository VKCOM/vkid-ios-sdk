#!/bin/sh

CERT="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
SIMNAME="iPhone 14 SSLPinTest"
SIMDEVICE="iPhone 14"
SIMID=""
SRC_ROOT="$(git rev-parse --show-toplevel)"


set_up_simulator () {
	echo "setting up simulator"
	SIMOS=$(xcrun simctl runtime list | awk '/-- iOS --/{f=1;next} /--/{f=0} f' | tail -n1 | cut -d ' ' -f 1-2 | tr -d ' ')
	echo "current runtime is $SIMOS"
	if [ -z "$SIMID" ]; then
		killall "Simulator"
		xcrun simctl list | grep -w "Shutdown"  | grep -o "([-A-Z0-9]*)" | sed 's/[\(\)]//g' | xargs -I uid xcrun simctl delete uid
		SIMID=$(xcrun simctl create "$SIMNAME" "$SIMDEVICE" "$SIMOS")

		if [ -n "$SIMID" ]; then
			echo "simulator have been set up with id $SIMID"
		else
			echo "failed to set up simulator"
			shut_down_proxy
			exit 1
		fi	
	else
		echo "pre-existing id used for simulator: $SIMID"
	fi
}

shut_down_proxy () {
	networksetup -setsecurewebproxystate $currentservice off

	sleep 1

	if [ -z "$PROXY_PID" ]; then
		echo "proxy is not running"
	else
		echo "shutting down proxy"

		kill -2 $PROXY_PID

		sleep 3

		if ps -p $PROXY_PID > /dev/null; then
		   echo "proxy failed to exit normally"
		   kill -9 $PROXY_PID
		fi

		unset PROXY_PID
	fi
}

run_test () {
	echo "testing $1 with package manager $2"
	echo "'SIMID is $SIMID'"

	local xcresult_artifact_path=$SRC_ROOT/build-artifacts/VKID_$2_$1.xcresult

	SCHEME="VKIDDemo"
	if [ $2 = "cocoapods" ]; then
		SCHEME="VKIDCocoapodsDemo"
	fi
	export TEST_RUNNER_PACKAGE_MANAGER=$2

	rm -rf $xcresult_artifact_path

	arch -x86_64 xcodebuild \
	-workspace $SRC_ROOT/VKIDDemo/VKIDDemo.xcworkspace \
	-scheme $SCHEME \
	-testPlan SSLPinning \
	-destination id=$SIMID -destination-timeout 120 \
	-resultBundlePath $xcresult_artifact_path \
	clean test -only-testing:VKIDSSLPinningTests/VKIDSSLPinningTests/$1 >& "$2 $1.log.txt"

	local RESULT="$?"
	if [[ "$RESULT" -eq 0 ]]; then
		echo "test $1 succeeded"
	else
		echo "test $1 failed with code $RESULT"
		if [[ "$RESULT" -eq 65 ]]; then
			echo "genuine failure"
		fi
		shut_down_proxy
		exit $RESULT
	fi
	eval "$3=$xcresult_artifact_path"
}

run_tests_with_allure () {
	local xcresults_tool_path=$SRC_ROOT/bin/xcresults
	local allure_results_folder=$SRC_ROOT/allure-results
	local xcresult_artifact_paths_string=""
	local return_val=""
	run_test testRequestIsCancelledIfTrafficIsSniffed spm return_val
	xcresult_artifact_paths_string="$return_val"
	run_test testRequestIsCancelledIfTrafficIsSniffed cocoapods return_val
	xcresult_artifact_paths_string="$xcresult_artifact_paths_string $return_val"
	shut_down_proxy

	run_test testRequestIsSucceededIfTrafficIsNotSniffed spm return_val
	xcresult_artifact_paths_string="$xcresult_artifact_paths_string $return_val"
	run_test testRequestIsSucceededIfTrafficIsNotSniffed cocoapods return_val
	xcresult_artifact_paths_string="$xcresult_artifact_paths_string $return_val"

	echo "Exporting allure results..."
	$xcresults_tool_path export $xcresult_artifact_paths_string -o $allure_results_folder
	echo "Allure results exported"
}

which mitmdump &> /dev/null
if [ $? -eq 1 ]; then
echo >&2 "mitmdump not found"
exit 1
fi

echo "preparing proxy..."

services=$(networksetup -listnetworkserviceorder | grep 'Hardware Port')

while read line; do
    sname=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $2}')
    sdev=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $4}')

    if [ -n "$sdev" ]; then
        ifout="$(ifconfig $sdev 2>/dev/null)"
        echo "$ifout" | grep 'status: active' > /dev/null 2>&1
        rc="$?"
        if [ "$rc" -eq 0 ]; then
            currentservice="$sname"
            currentdevice="$sdev"
            currentmac=$(echo "$ifout" | awk '/ether/{print $2}')

            echo "$currentservice, $currentdevice, $currentmac"
            break
        fi
    fi
done <<< "$(echo "$services")"

if [ -z "$currentservice" ]; then
    >&2 echo "Could not find current service"
    exit 1
fi

networksetup -getsecurewebproxy $currentservice | grep  "Enabled: Yes" > /dev/null
if [  $? -eq 0 ]; then
    >&2 echo "Network proxy is already enabled by someone else in settings"
fi

echo "starting proxy..."

> ./nohup.out
nohup mitmdump -p 8080 -q &
PROXY_PID=$!

echo "pid is $PROXY_PID"

sleep 3

echo "setting proxy up in settings..."

networksetup -setsecurewebproxy $currentservice 0.0.0.0 8080

set_up_simulator

if [[ ! -e "$CERT" ]]; then
    echo "mitmproxy ca certificate not found at $CERT"
	networksetup -setsecurewebproxystate $currentservice off
	shut_down_proxy
    exit 1
fi

echo "pushing proxy certificate authority to simulators"

xcrun simctl boot "$SIMID"
xcrun simctl keychain "$SIMID" add-root-cert "$CERT"

run_tests_with_allure

echo "all tests succeeded"
