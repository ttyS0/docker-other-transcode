#!/bin/sh

mkdir -p 8bit 10bit

cd 10bit
cmake ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_CLI=OFF
make ${MAKEFLAGS}

cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
cmake ../../../source -DEXTRA_LIB="x265_main10.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DCMAKE_INSTALL_PREFIX=/opt/ffmpeg -DENABLE_CLI=OFF
make ${MAKEFLAGS}

# rename the 8bit library, then combine all three into libx265.a
mv libx265.a libx265_main.a

## On Linux, we use GNU ar to combine the static libraries together
#ar -M <<EOF
#CREATE libx265.a
#ADDLIB libx265_main.a
#ADDLIB libx265_main10.a
#SAVE
#END
#EOF

slibtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a
