#!/bin/bash

BASE="iSoul"
PERMISSIONFILE="dsa_priv.pem"

# test if we have the files we need
if [ ! -d "$BASE.app" ]; then
	echo "Couldn't find $BASE.app!"
	exit
fi
if [ ! -f "$PERMISSIONFILE" ]; then
	echo "Couldn't find $PERMISSIONFILE!"
	exit
fi

# get version info
echo "Getting version info..."
VERSION=$(defaults read "`pwd`/$BASE.app/Contents/Info" CFBundleShortVersionString)
ARCHIVENAME="$BASE $VERSION.zip"

# compress app
echo "Compressing..."
rm -f "$BASE"*.zip
zip -qry9X "$ARCHIVENAME" "$BASE.app"

# get size, date and signature
echo "Signing..."
SIZE=$(stat -f %z "$ARCHIVENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")
SIGNATURE=$(ruby sign_update.rb "$ARCHIVENAME" "$PERMISSIONFILE")
SIGNATURE=$(echo $SIGNATURE | sed 's/\+/\\\+/g' | sed 's/\//\\\//g')

# create appcast
echo "Creating appcast..."
cat appcast.xml |
sed "s/@VERSION@/$VERSION/g" |
sed "s/@PUBDATE@/$PUBDATE/g" |
sed -E "s/@SIGNATURE@/$SIGNATURE/g" |
sed "s/@SIZE@/$SIZE/g" > ../appcast.xml

echo "Done!"
