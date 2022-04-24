#!/bin/bash

# *** CONFIG ***
VERSION="v8.15.0"
DEPENDENCIES=(
  "FirebaseAnalytics"
  "FirebaseAuth"
  "FirebaseFirestore"
  "FirebaseFunctions"
  "FirebaseStorage"
)
EXCLUDE_ARCHES=(
  "tvos"
  "macos"
  "maccatalyst"
)
REQUIRED_FILES=(
  "Firebase.h"
  "module.modulemap"
)

# *** CODES ***

TARGET_PATH="../xcframeworks/Firebase"

if [ -d $TARGET_PATH ]; then
  rm -r $TARGET_PATH
fi
# fetch xcframeworks
wget https://github.com/firebase/firebase-ios-sdk/releases/download/$VERSION/Firebase.zip -O Firebase.zip
unzip Firebase.zip
rm Firebase.zip

#copy modulemap, header
mkdir $TARGET_PATH
for dep in ${REQUIRED_FILES[@]};
do
  cp Firebase/$dep ${TARGET_PATH}/$dep
done

# find all xcworkspaces in DEPENDENCIES
greps="grep"
for dep in ${DEPENDENCIES[@]};
do
  greps="$greps -e $dep"
done
xcframeworks=$(find Firebase -name "*.xcframework" -maxdepth 2 | $greps)

# find all xcworkspaces in DEPENDENCIES
exclude_arch_args=""
for arch in ${EXCLUDE_ARCHES[@]};
do
  exclude_arch_args="$exclude_arch_args --exclude=*${arch}*"
done

# copy xcworkspaces but not duplicated (their version must be same)
copied_xcframeworks=""
for xcframework_path in ${xcframeworks[@]};
do
  xcframework_name=$(basename $xcframework_path)
  if [[ ! "$copied_xcframeworks" == *"$xcframework_name"* ]]; then
    copied_xcframeworks="$copied_xcframeworks $xcframework_name"
    rsync -a $exclude_arch_args $xcframework_path $TARGET_PATH
  fi
done

# clean up
rm -r Firebase

echo "Firebase dependency injected."

