extends Node

enum Type {DEVIL, OBSERVER, TROLL}

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
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Wise Choice, i know you'll choose it from the very first time"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Anyway, let me introduce you to the stream, so.."},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Hi cutie... I'm Lilith, i can't wait to see your... fate"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "Don't mind that pervert, by the way I'm Ereshkigal, nice to meet you"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "..."},
		{
			"type": Type.TROLL,
			"user": "Ghull",
			"text": "Haha, that old man. Hi i'm Ghull, do you want some magic power?",
			"is_offer": true,
			"offer_id": "TROLL_1"
		},
	],
	"TROLL_1_accepted": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "What an idiot."},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Hahaha, not all offer is good for you"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Anyway let's move, i'm sure you wan't to escape this realm right?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Give me some entertainment, why don't you search for some torch? Maybe it somewhere up there"},
	],
	"TROLL_1_rejected": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "Clever move"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Hahaha, anyway let's move, i'm sure you wan't to escape this realm right?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Come on, entertain me. Why don't you search for a torch? I'm pretty sure it's up there."},
	],
	"found_torch": [
		{"type": Type.OBSERVER, "user": "Hades", "text": "There you are, now try to get used to the torch and try to go to the right end of this realm"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Funfact, you can use the torch to make some enemies stunt"},
	],
	# RESPON JIKA TOLAK
	"soul_trade_01_rejected": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "This is on you. Choosing you was a mistake"},
	],
	
	#tutorial pertama:
	"tutorial_torch": [
		{"type": Type.OBSERVER, "user": "Lilith", "text": "There you are, it still dark isn't it ?"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Go find some torch so you can see me clearly~"},
		{"type": Type.TROLL, "user": "Hecate", "text": "Ugh, disgusting"},
		{
			"type": Type.TROLL,
			"user": "Hecate",
			"text": "I *might* know where the torch is. Want a hint?",
			"is_offer": true,
			"offer_id": "TROLL_2"
		},
	],
	
	"TROLL_2_accepted": [
		{"type": Type.TROLL, "user": "Hecate", "text": "It's definitely not on the left."},
		{"type": Type.TROLL, "user": "Hecate", "text": "And certainly not on the right."},
		{"type": Type.TROLL, "user": "Hecate", "text": "Unless, of course… it's above you. Or below."},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Hey, stop messing with him!"},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Once you find the torch, press 'F' to use it."},
		{"type": Type.OBSERVER, "user": "Lilith", "text": "You can aim it with your mouse."},
		{"type": Type.TROLL, "user": "Ghul", "text": "Perhaps, someone nearby knows where it is."},
	],
	"TROLL_2_rejected": [
		{"type": Type.TROLL, "user": "Hecate", "text": "Tartar sauce, fk you"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "GO find the torch. Press 'F' to use it"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "Control it with your mouse"},
		{"type": Type.TROLL, "user": "Ghul", "text": "Someone here might be watching… and waiting to help our little friend."},
	],
	
	#tutorial kedua:
	"tutorial_chat": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "The chat is annoying? You should've said so sooner"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You can click the `Tab` button to remove it, and `Tab` again to pop it up"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "Now, find the exit of this realm. It may lie deep within the dungeon."},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "By the way, you can use 'shift' key for run, but make sure you don't run out of stamina, you weakling"},
		
	],
	
	#tutorial ketiga:
	"tutorial_final_objective": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You may search for more before you leave… or walk out now. The choice is yours"},
	],

	"beginning": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Did I ever say you could leave Hell as easily like this lol"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You're such a fool"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You are Indonesian, you must have some attitude right? go find the owner of the house and ask for his permission to leave"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Where, you ask??"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "I don't know, goodluck little fool"},
	],
	"Pengecoh1": [
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "I heard it from old man Zeus back them, the Helheim is one of the most dangereous place in this realm, moreover there is Tartarus there, where Nidat, the ancestor of Titan was trapped in"},
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "I know little else… but keep your torch lit at all times"},
		{
			"type": Type.TROLL,
			"user": "Ghul",
			"text": "Psst. Want the boss location? This time, I swear! No tricks ^^",
			"is_offer": true,
			"offer_id": "TROLL_M_1"
		},
	],
	"TROLL_M_1_accepted": [
		{"type": Type.TROLL, "user": "Ghul", "text": "Wise choice"},
		{"type": Type.TROLL, "user": "Ghul", "text": "The boss room should be somewhere southwest. Look for a wall shaped like broken stairs."},
		{"type": Type.OBSERVER, "user": "Hades", "text": "Stay alert for the monsters, they WILL attack you"},
	],
	"TROLL_M_1_rejected": [
		{"type": Type.TROLL, "user": "Ghul", "text": "Guess you'll find out the hard way"},
		{"type": Type.OBSERVER, "user": "Hades", "text": "Stay alert for the monsters, they WILL attack you"},
	],
	"Pengecoh2": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "I smell a foul stench from Tempra, we must be getting close"},
	],
	"Pengecoh3": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "This black aura... how peculiar. The boss room should be nearby."},
	],
	"Pengecoh4": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You found another path? Good good"},
	],
	"Pengecoh5": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "These small rooms reek worse than Tempra. Perhaps this is Chasy's scent"},
	],
	"Pengecoh6": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "This place is unbearable. Find what you need; and faster!!!"},
	],
	"Came_Earlier": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "You arrived quickly. So… where is the sesajen?", "is_offer": true, "offer_id": "placeholder"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "What offering, you ask?"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Insolent child! Dare to meet me empty-handed?"},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Find the five Heads of Heavenly Virtues (the enemies of Seven Deadly Sins) across the realms"},
	],

	"diam1": [
		{"type": Type.OBSERVER, "user": "Hades", "text": "Do you want your legs cut off? MOVE!"},
	],
	"diam2": [
		{"type": Type.OBSERVER, "user": "Ereshkigal", "text": "Why the silence? Did you find something suspicious?"},
	],
	"diam3": [
		{"type": Type.OBSERVER, "user": "Lilith", "text": "Standing around won't get you anywhere~ Hurry up and move cutie~"},
	],
	"BigClue1": [
		{
			"type": Type.TROLL,
			"user": "Huli Jing",
			"text": "Having trouble finding the key? I can help you out",
			"is_offer": true,
			"offer_id": "TROLL_BC_1"
		},
	],
	"TROLL_BC_1_accepted": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "Have you checked the corners of this realm and your starting realm?"},
	],
	"TROLL_BC_1_rejected": [
		{"type": Type.TROLL, "user": "Huli Jing", "text": "...ok"},
	],

	"BigClue1D": [
		{
			"type": Type.DEVIL,
			"user": "Lucifer",
			"text": "You should've learned from your mistakes, I can also offer you guidance if you want, with a price of course.",
			"is_offer": true,
			"offer_id": "DEVIL_BC_1"
		},
	],
	"DEVIL_BC_1_accepted": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Have you checked the corners of this realm and the tutorials realm?"},
	],
	"DEVIL_BC_1_rejected": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "..."},
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Not my problem."},
	],

	
}
