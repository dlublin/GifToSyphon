# About GifToSyphon
This is a simple tool for downloading and playing back animated GIFs from Giphy for remixing in VJ applications that support Syphon video sharing on the Mac.

The latest release version can be downloaded from here:
https://github.com/dlublin/GifToSyphon/releases

Read more about how to use GifToSyphon in this blog post:
http://vdmx.vidvox.net/blog/giftosyphon

GifToSyphon requires Mac OS 10.9.5 or later.


#History

In the process of replacing some old QuickTime movie playback code with AVFoundation counterparts I needed to write a test sandbox app for animated GIF playback as it isn't supported by AVPlayer. After it was written there was a secondary need to download lots of sample GIFs to test against to make sure everything working properly. Thankful Giphy has a great, simple and free API for pulling images from their library. Once that was going it was pretty clear this needed to be published to Syphon so we could access the GIF search during live performances.


#Compiling your own version

To compile this application yourself you'll also need to check out a copy of VVOpenSource:
https://github.com/mrRay/vvopensource

This code uses a public API key from Giphy – if you're serious about running your own fork of this project you'll want to get in touch with them to get your own private API key that can be placed in the AppController.h defines. For more information on the Giphy API visit their webpage here: https://api.giphy.com/

The GIF playback code section is broken up into three objects:
- VVGIFFrame: Wrapper for a single GIF frame.
- VVGIFPlayerItem: Representation of an animated GIF file. Maintains an array of VVGIFFrames.
- VVGIFPlayer: Playback controller for animated GIF files.

In the AppController you'll find the code for:
- A simple rendering engine based on VVBufferPool. In the render thread bitmaps are pulled from the VVGIFPlayer and converted into VVBuffers for display and publishing to Syphon.
- Handling the getting links to GIFs from Giphy. Uses VVCURLDL to make an asynchronous connection to request a random GIF and JSONKit to interpret the returned result.
- Loading and interfacing with instances of a VVGIFPlayer.


#Licensing

This release version of this project is provided as-is, use at your own risk. That said, please feel free to contact me about any issues.

All downloaded GIFs and imagery belong to their original copyright holders. GIF downloading powered by Giphy.

Syphon video sharing on the Mac is an open source project by Bangnoise and Vade, more information here: http://syphon.v002.info/

The source code of this project is licensed under a Free BSD License (https://www.freebsd.org/copyright/freebsd-license.html), meaning you can use it in your commercial or noncommercial applications free of charge. Some classes in this project use code from other open-source projects. At present, the third-party code used includes VVOpenSource from Ray Cutler and JSONKit by John Engelhart.


#Screenshot
![alt text](https://github.com/dlublin/GifToSyphon/blob/master/GifToSyphon/Screenshots/GifToSyphonScreenshot.png "GifToSyphon Screenshot")
