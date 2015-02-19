# About GifToSyphon
Downloads and playsback GIFs from Giphy, then publishes them to Syphon for remixing in other applications.

The latest release version can be downloaded from here:
<<download link>>

Read more about how to use GifToSyphon in this blog post:
<<blog post link>>


#Compiling your own version

To compile this application yourself you'll also need to check out a copy of VVOpenSource:
https://github.com/mrRay/vvopensource
(this is used for the rendering engine and also includes JSONKit)

This code uses a public API key from Giphy – if you're serious about running your own fork of this project you'll want to get in touch with them to get your own private API key that can be placed in the AppController.h defines. For more information on the Giphy API visit their webpage here: https://api.giphy.com/


#Licensing

This release version of this project is provided as-is, use at your own risk.

All downloaded GIFs and imagary belong to their original copyright holders. GIF downloading powered by Giphy.

The source code of this project is made available under the terms of the LGPL: http://www.gnu.org/copyleft/lesser.html. Some classes in this project use code from other open-source projects. At present, the third-party code used includes VVOpenSource from Ray Cutler and JSONKit by John Engelhart.
