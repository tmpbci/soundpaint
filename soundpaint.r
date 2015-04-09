
REBOL [ Title: "Soundpaint" 
	author: Sam Neurohack
	description: Convert pictures in midi music with point animation. Uses Pd-Extended to send midi event
	Version: 0.1
]

;;
;; Initial setup 
;;

do %jresources/ieee.r

namefile: %photo.jpg					; must be %path/to/filename
tempocc: 0.1							; Duration (sec) will set default tempo
pixelstep: 300							; 
pentac: array/initial 10 0
pentac: [0 2 4 7 9] 					;  C major pentatonic scale : C=0 D=2 E=4, G=7, A=9 see midinote image
panval: 65
bendval: 0

data: make binary! 1000
host_name: system/network/host
lan: 0
allred: 0
allgreen: 0
allblue: 0
rgbh: 0.0.0.0							; rgbh will get the complementary color tuple.
rgb: 0.0.0.0
testarray: [0.0.0.0 0.0.0.0 0.0.0.0 0.0.0.0]
				
length-gamme: length? pentac
octmelody: 5							; Center and nb of possible octave for melody
nboctmelody: 4
nboctchords: 1							; Center and nb of possible octave for melody
octchords: 3
currentnote: 0
thisnote: 0								; this note 
chordnote: 1


nbnotes: nboctmelody * length? pentac
pentacn: array/initial nbnotes 0

chordsm: [0 4 7]							; Major chord C=0 E=4 G=7 
chordsmn: array/initial [30 3] 0

;;
;; Precomputing all Midi notes numbers according to the pentac variable for chosen number of octave 
;;

for j 0 (nboctmelody - 1) 1 					; for Major pentatonic scale midi note number for all melody octaves
		
			[
			for iz 1 length-gamme 1 [pentacn/(iz + (length-gamme * j)): pentac/(iz) + (12 * (octmelody + j))]
			]

for i 1 length-gamme 1 [											; for Major chords for pentatonic scale
			chordsmn/(i)/1: (pentac/(i) + chordsm/1) + (12 * octchords)
			chordsmn/(i)/2: (pentac/(i) + chordsm/2) + (12 * octchords)
			chordsmn/(i)/3: (pentac/(i) + chordsm/3) + (12 * octchords)
			]
				
print pentacn
print chordsmn

;;
;; Bunch of functions
;;
;; Jump to Start UIs if you want to follow execution
;;

Get_Os: does [
	switch system/version/4 [
		3 [os: "Windows" countos: "n"]
		2 [os: "MacOSX" countos: "c"]
		4 [os: "Linux" countos: "c"]
		5 [os: "BeOS" countos: "c"]
		7 [os: "NetBSD" countos: "c"]
		9 [os: "OpenBSD" countos: "c"]
		10 [os: "SunSolaris" countos: "c"]
	]
]

;;
;; Generate and send Midi note and velocity to tcp port of Pd Patch
;;

domelody: does [			   
				thisnote: pentac/(root) + (12 * octv)					; get note with root and octave
				print ajoin ["RGB : " rgb/1 " " rgb/2 " " rgb/3 " octave : " octv " pan : " panval " root : " root " this : " thisnote]
				newval: [thisnote velocity]
				;print pentac
				currentnote: pentacn/(thisnote)
				newdata: reform newval
				either lan = 1 [insert notesport newdata
								status/text: ajoin [" note velocity : " newdata]
								print ajoin ["note velocity " newdata]
								show status
								;print to-integer tcount/text
								]
							   [print "Lan is not connected"]
				]
;;
;; Generate and send Midi CC to tcp port of Pd Patch
;;

docc: does [				   																			; send according pan and bend modification
				print ajoin ["root : " root " this : " thisnote " note : " (pentacn/(thisnote)) " chord : " chordnote  " cnote : " chordsmn/(chordnote)/1]
				newval: [1 1 panval bendval 1 1 1 1 1 1]
				newdata: reform newval
				print ajoin ["pan bend : " newdata]
				either lan = 1 [insert chordsport newdata]
							   [print "Lan is not connected"]
				wait tempocc
				]
;;
;; RGB to HSV 
;;

rgbtohue: does [
    print rgb
	RGB.R: (rgb/1) / 255
	RGB.G: (rgb/2) / 255
	RGB.B: (rgb/3) / 255
	minrgb: min RGB.R (min RGB.G RGB.B)
	maxrgb: max RGB.R (max RGB.G RGB.B)
	v: maxrgb								; v

	delta: maxrgb - minrgb
	if delta = 0 [delta: 1]

	either maxrgb <> 0 	[s: delta / maxrgb]		; s							
						[s: 0					; r = g = b = 0 s = 0, v is undefined
					 	h: -1
					 	exit
					 	]

	either RGB.R = maxrgb 	[h: (RGB.G - RGB.B) / delta]								; between yellow & magenta
							[either RGB.G = maxrgb [h: 2 + ((RGB.B - RGB.R) / delta)]	; between cyan & yellow
											[h: 4 + ((RGB.R - RGB.G) / delta)]			; between magenta & cyan
							]
	h: h * 60																			; degrees
	if h < 0 [h: h + 360]		

	;print ajoin ["h : " h " s : " s " v : " v]

]

;;
;; HSV to RGB (to get the complementary hue hh for better animation visibility)
;;

huetorgb: does [
	
	s: 0.9
	v: 0.9
	
	either s = 0 [RGB.R: v * 255
		 		  RGB.G: v * 255
				  RGB.B: v * 255]

			[hh: hh / 60
			idec: to-integer hh
			f: hh - idec
			h1: v * (1 - s)
			h2: v * (1 - (s * f))
			h3: v * ((1 - s) * (1 - f))
		
			case [
				idec = 0 [ r: v 
					    g: h3 
					    b: h1]
					  
				idec = 1 [ r: h2
					    g: v 
					    b: h1]
			
				idec = 2 [ r: h1 
			 			g: v 
						b: h3]
			 
				idec = 3 [ r: h1
						g: h2 
						b: v]
						
				idec = 4 [ r: h3 
				  		g: h1 
				  		b: v]
				  		 
				idec > 4 [ r: v
				  		g: h1 
				  		b: h2]
				]
			rgbh/1: to-integer (r * 255)
			rgbh/2: to-integer (g * 255)
			rgbh/3: to-integer (b * 255)
		    ]
	]
	
;;
;; compute picture parameters
;;

compute: does [
				count: 1
				current: 1
				element: 1
				allred: 0
				allgreen: 0
				allblue: 0
				wait 0.05
				print "Computing statistics..."
				sizex: image1/size/x
				sizey: image1/size/y
				pixels: (sizex * sizey)
				centerelement: pixels / 2
				centerx: to-integer sizex / 2
				centery: to-integer sizey / 2
				print ["Pixels : " pixels]
				print ["Taille : " image1/size]
				print ["Width : " sizex]
				print ["Height : " sizey]
				print ["center : " centerelement]
															
				for newelement 1 pixels 1 [
											rgb: image1/image/(newelement)
											allred: allred + rgb/1
											allgreen: allgreen + rgb/2
											allblue: allblue + rgb/3
											]
				allcolors: (pixels * 255) * 3	
				print ajoin ["Reds : " allred " Greens : " allgreen " Blues : " allblue]
				print ajoin ["Reds : " allred / allcolors " Greens : " allgreen  / allcolors" Blues : " allblue  / allcolors]
]

;;
;; Controllers UI
;;

controllers: layout [
	anti-alias on
	backdrop effect [gradient 1x1 0.0.0 50.50.50] 
	at 20x10 text "Soundpainter" white
	at 230x13 hgambciled: led green
	at 20x35 status: info bold "Ready." 220x25 font-color white 
;; Live recording buttons
	at 20x70 text "Controllers" snow       
	at 197x70 tcount: text "00000" snow
	at 100x95 button 70 50.50.50 edge [size: 1x1] "Run" [

			restart: 1
			stoploop: 0
			status/text: "Running..."
			show status
			for element ((3 * sizex) + 4) (pixels - (4 * sizex)) pixelstep
				[ 
				tcount/text: element
				show tcount
				currentelement: element
				print " "
				print "New Note"
				rgb3: image1/image/(currentelement)							; save pixels colors for anim
				rgbl: image1/image/(currentelement - sizex)
				rgbr2: image1/image/(currentelement + sizex)
				rgbr: image1/image/(currentelement + 1)
				rgb22: image1/image/(currentelement - 1)
				rgbl3: image1/image/(currentelement + (2 * sizex))
				rgbl4: image1/image/(currentelement - (2 * sizex))
				rgbl5: image1/image/(currentelement - sizex - 1)
				rgbl2: image1/image/(currentelement - sizex + 1)
				rgbl6: image1/image/(currentelement - (3 * sizex))
				rgb: rgb3													; compute current HSV.
				rgbtohue
				
				case [														; current hue value -> tempo change
					h < 50 [tempocc: 0.05
							]
					h < 80 [tempocc: 0.1
							]
					h < 140 [tempocc: 0.5
							]
					h < 280 [tempocc: 1
							]
					h < 360 [tempocc: 0.05
							]
					 ]
				;print ajoin ["rgb: " rgb " rgb3: " rgb3]
				
				case [														; Velocity and octave depends on current "value" (v of HSV)
					v < 0.2	[
								velocity: (40 + random 20) 					
								octv: 2]
					v < 0.40	[
								velocity: (70 + random 20) 
								octv: 3]
					v < 0.6	[
								velocity: (40 + random 20) 					
								octv: 4]
					v < 0.80	[
								velocity: (70 + random 20) 
								octv: 5]	
					v < 0.9	[
								velocity: (70 + random 20) 
								octv: 6]										   																						
					v <= 1		[
								velocity: (100 + random 20) 
								octv: 7
								]
					]
				;print ajoin ["octv : " octv " velocity : " velocity]
				hh: h + 180													; compute complementary hue hh = +-180° of h
				if hh = 179 [rgbh: 255.255.255.0]
				if hh > 360 [hh: hh - 360]
				huetorgb
				
				image1/image/(currentelement): rgbh							; change anim pixels
				image1/image/(currentelement - sizex): rgbh
				image1/image/(currentelement + sizex): rgbh
				image1/image/(currentelement + 1): rgbh
				image1/image/(currentelement - 1): rgbh
				image1/image/(currentelement + (2 * sizex)): rgbh
				image1/image/(currentelement - (2 * sizex)): rgbh
				image1/image/(currentelement - sizex - 1): rgbh
				image1/image/(currentelement - sizex + 1): rgbh
				image1/image/(currentelement - (3 * sizex)): rgbh
				show image1
																						; test 4 points for global color "value" (HSV) orientation -> wich note (root) inside the chosen scale (pentac variable)
				testarray/1: image1/image/(currentelement - 3 - (3 * sizex))			; 1 Left top
				testarray/2: image1/image/(currentelement + 3 - (3 * sizex))			; 2 right top
				testarray/3: image1/image/(currentelement - 3 + (3 * sizex))			; 3 left bottom
				testarray/4: image1/image/(currentelement + 3 + (3 * sizex))			; 4 right bottom
				
				rgb: testarray/1														; get color "value" of these 4 pints
				rgbtohue
				v1: v
				rgb: testarray/2
				rgbtohue
				v2: v
				rgb: testarray/3
				rgbtohue
				v3: v
				rgb: testarray/4
				rgbtohue
				v4: v
				vmedian: (v1 + v2 + v3 + v4) / 4										; get mean "value"
				
				;print ajoin ["v1 : " v1 " v2 : " v2 " v3 : " v3 " v4 : " v4 " vm : "vmedian]
				
				root: 5																	; Compute root note with all other case root = 5
				
				if all [v1 > vmedian v3 > vmedian v2 < vmedian v4 < vmedian] [root: 1]	; 1 orientation vertical
				if all [v1 < vmedian v3 < vmedian v2 > vmedian v4 > vmedian] [root: 1]	; 1 orientation vertical
				
				if all [v1 > vmedian v2 > vmedian v3 < vmedian v4 < vmedian] [root: 2]	; 2 orientation horizontal
				if all [v1 < vmedian v2 < vmedian v3 > vmedian v4 > vmedian] [root: 2]	; 2 orientation horizontal
				
				if all [v1 > vmedian v4 > vmedian v2 < vmedian v3 < vmedian] [root: 3]	; 3 orientation cross LR
				if all [v1 > vmedian v3 > vmedian v2 < vmedian v3 < vmedian] [root: 4]	; 4 orientation cross RL
				rgb: rgb3
				rgbtohue
				
				domelody
				docc
				
				;print ajoin ["backup element : " element " " rgb " " rgbl " " rgbr]
				wait 0.5
				image1/image/(currentelement): rgb3
				image1/image/(currentelement - sizex): rgbl
				image1/image/(currentelement + sizex): rgbr2
				image1/image/(currentelement + 1): rgbr
				image1/image/(currentelement - 1): rgb22
				image1/image/(currentelement + (2 * sizex)): rgbl3
				image1/image/(currentelement - (2 * sizex)): rgbl4
				image1/image/(currentelement - (3 * sizex)): rgbl6
				image1/image/(currentelement - sizex - 1): rgbl5
				image1/image/(currentelement - sizex + 1): rgbl2
				show image1
																													 	
				if stoploop = 1 [status/text: "Stopped !"
								show status
								break]
				    			]
				]
	at 20x130 button 70 50.50.50 edge [size: 1x1] "Stop" 	[
															status/text: "Stopping..."
															show status
															stoploop: 1
															]
	at 185x95 button 70 50.50.50 edge [size: 1x1] "Quit" [quit]		
															  
	at 20x95 jlivebtn: button 70 50.50.50 edge [size: 1x1] "Local" [
										either lan <> 1 [
													lan: 1
       												chordsport: open/lines tcp://localhost:13856
       												notesport: open/lines tcp://localhost:13857
       												status/text: "Send Data ON"
       												show status]
       												[
       												lan: 0
       												close chordsport
       												close notessport
       												status/text: "Send Data Off"
       												show status
       												]
       									]
	]
;
; old stuff not used.
;


Set_TimeOut: func [newto] [
	oldto: system/schemes/default/timeout
	system/schemes/default/timeout: newto
]

Restore_TimeOut: does [
	system/schemes/default/timeout: oldto 
]

;;
;; PhotoUI
;;

photoui: layout [
	backdrop effect [gradient 1x1 0.0.0 10.10.10]
    at 10x10 image1: image load namefile
    ]
;;
;; Start UIs
;;

view/new photoui
view/new controllers
compute

do-events

