extends Node

enum Type { DEVIL, OBSERVER, TROLL }

# Database pesan hardcode
const MESSAGES = {
	"welcome_event": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Welcome dear Desmond..."},
		{
			"type": Type.TROLL, 
			"user": "Stranger", 
			"text": "Mau HP gratis? Cukup bayar pakai jiwamu.",
			"is_offer": true,
			"offer_id": "soul_trade_01"
		}
	],
	"room_entry_1": [
		{"type": Type.DEVIL, "user": "Lucifer", "text": "Kau akan mati di sini, itu fakta."},
		{"type": Type.TROLL, "user": "u_mad_bro", "text": "Lari aja bang, cupu amat."}
	],
	"near_cultist": [
		{"type": Type.OBSERVER, "user": "Watcher", "text": "Mereka sedang melakukan ritual pemanggilan."},
		{"type": Type.DEVIL, "user": "Beelzebub", "text": "Darahmu adalah bahan utamanya."}
	],
	"standing_still": [
		{"type": Type.TROLL, "user": "AFK_Killer", "text": "Halo? Masih hidup?"}
	]
}
