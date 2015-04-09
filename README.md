Soundpaint v 0.1
by Sam Neurohack : sam at neurohack dot cc
Convert pictures in music via midi with point animation.
CC BY NC 

In this version every 300 pixels, octave is chosen according to color value ("value" as in HSV color code), hue control part of tempo and 4 near pixels color values control the note choice inside pentatonic scale.


This is rough software for a /tmp/lab photo workshop at Mediatheque Choisy le Roi on Saturday 24 jan 2015. It's not meant to be nicely programmed but a lot of comments are present.
Due to the use of Rebol and Pd this program is natively cross platform : Linux, OS X, Windows.

Needs a midi instrument on channel 1. (I use a virtual piano).
Needs Pd-Extended. This patch open a tcp server to receive datas from the main program and forward them in midi environement.
Needs rebol 2.7. Easiest way is to copy the rebol binary (http://www.rebol.com) in /usr/bin or anywhere in the Path.

The program automatically open photo.jpg. You can change the file but keep the name or edit the code.
The default tempo is in second in tempocc variable.
Feel free to modify the initial setup lines values to you your needs.

How to use :

- Start the midi instrument.
- Open jresources/jpdtcp2.pd with pure data.
- You Need to check midi Pure Data preferences to be sent to your midi instrument.
- Type rebol soundpaint.r in a terminal or double click the icon in windows.

- Click Local to link with Pure Data patch.
- Click run.

Notes :

- It's a short version of a more complex program that translate brain visual areas work in music, while watching a picture. Ask if you want it.
- Therefore, this program compute much more data that it actually use. You may want to use them.
- Rebol 2.7 can load natively jpg, png, gif and bmp.
- Please note that there is no resize of photo.jpg in this version. Resize the picture first to fit in your screen resolution if you want to see point animation.
- If you are unfamiliar with Rebol, you may read about its great image datatype and its refinements : http://www.rebol.com/docs/image.html
- This program use absolute pixel position (currentelement) instead of X Y positioning.
- The localhost tcp ports 13856 and 13857 will be used.

Troubleshooting :

No sound ?
- check your midi instrument, channel 1 ?
- check Pure Data midi settings to point to your midi instrument ? try click midi out in testnote.pd that should come with Pd.
- If terminal read "Lan is not connected" click Local and/or start jpdtcp2.pd patch first.
- Send me an email with your configuration if it still doesn't work but testnote.pd works fine.

	