extends Node

enum Type { DEVIL, OBSERVER, TROLL }

# Database pesan hardcode
const MESSAGES = {
	#awalan
	"welcome_event": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Welcome dear Sam..."},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "A bit dark isn't it ?"},
		{
			"type": Type.DEVIL, 
			"user": "Lucifer", 
			"text": "Would you like to trade a visibility enhancer for a bit of your soul ?",
			"is_offer": true,
			"offer_id": "soul_trade_01"
		},
	],
	"soul_trade_01_accepted": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Wise Choice, i know it's you from very first time"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Anyway, look, let me introduce you to the stream, so.."},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Hi cutie... I'm Lilith, i can't wait to see your... fate"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "don't mind that pervert, by the way I'm Ereshkigal, nice to meet you"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "..."},
		{
			"type": Type.TROLL, 
			"user": "Ghull", 
			"text": "haha, that old man still quiet, hi i'm Ghull, do you wanna magic power?",
			"is_offer": true,
			"offer_id": "TROLL_1"
		},
	],
	"TROLL_1_accepted": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "such a foolish"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "hahaha, not all offer is good for you"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "anyway let's move, i'm sure you wan't to quit this realm right?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "that's right, give me some good movies to watch, why don't you search for some torch? maybe it somewhere up there"},
	],
	"TROLL_1_rejected": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "what a clever boy we have here"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "hahaha, i knew it, anyway let's move, i'm sure you wan't to quit this realm right?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "that's right, give me some good movies to watch, why don't you search for some torch? maybe it somewhere up there"},
	],
	"found_torch": [
		{"type": Type.OBSERVER, "user": "Hades", "text": "There you are, now try to get used to the torch and try to go to the right end of this realm"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "By the way, you can use the torch to make some enemies stunt"},
	],
	# RESPON JIKA TOLAK
	"soul_trade_01_rejected": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You made me furious, i'm wrong to choose this little bastard"},
	],
	
	#tutorial pertama:
	"tutorial_torch": [
		{"type": Type.OBSERVER, "user": "Lilith", "text": "There you are, it still dark isn't it ?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Go find some torch so you can see me clearly~"},
		{"type": Type.TROLL, "user": "Hecate", "text": "Ugh, disgusting"},
		{
			"type": Type.TROLL, 
			"user": "Hecate", 
			"text": "Anyway, i probably not unknown where the torch is not supposed to be, do you want some hint?",
			"is_offer": true,
			"offer_id": "TROLL_2"
		},
	],
	
	"TROLL_2_accepted": [
		{"type": Type.TROLL, "user": "Hecate", "text": "It' probably not on the left, or maybe not on the right"},
		{"type": Type.TROLL, "user": "Hecate", "text": "Or... maybe its up or down"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Ow, cmon guys, don't make fool of him!"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "just after you found it, you can use it by clicking 'F'"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "And you can control it with your mouse"},
		{"type": Type.TROLL, "user": "Ghul", "text": "Maybe someone there could help you found the torch"},
	],
	"TROLL_2_rejected": [
		{"type": Type.TROLL, "user": "Hecate", "text": "saus tartar"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "hmph, just after you found it, you can use it by clicking 'F'"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "and control it with your mouse"},
		{"type": Type.TROLL, "user": "Ghul", "text": "Maybe someone there could help you found the torch"},
	],
	
	#tutorial kedua:
	"tutorial_chat": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "The chat is too annoying you say? Why didn't you say so from the start?"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You can click the tab button to remove it, and tab again to pop it up"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "Now you have to find the exit door of this realm, maybe it's in the bottom of the dungeon"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "By the way, you can use 'shift' key for run, but make sure you don't run out of stamina, you are weak tho"},
		
	],
	
	#tutorial ketiga:
	"tutorial_final_objective": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Maybe you wanna find some more stuff before you leave, but you can just leave this realm"},
	],

	"start_main_map":[
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Did i mention you can just leave from hell like you go out of your nanny's house?"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "GAHAHAHAHAHAH, you fool"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You are Indonesian, you must've some attitude right? go find the owner of the house and have his permission to leave"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Where you say??"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "I don't know, goodluck boy"},
	],
	"begining":[
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "I heard it from old man zeus back them, the Helheim is one of the most danger place in over realm, moreover there is tartarus there, where Nidat, the ancestor of Titan was trapped in"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "I didn't know much about this place, but i'm sure you have to turn your torch always on"},
	],
}
