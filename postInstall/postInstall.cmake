message( STATUS "post install process ...")
execute_process( COMMAND pwd )
message( STATUS "add libraries to bundle ...")
execute_process( COMMAND python postInstall/libBundleCloudCompare.py )
message( STATUS "signature ...")
execute_process( COMMAND bash postInstall/signatureCloudCompare.sh )
message( STATUS "... Done")