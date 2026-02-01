extends Area2D

# Menggunakan enum agar pilihan di Inspector berupa dropdown (lebih aman dari typo)
enum ItemList { SENTER, KUNCI, POTION }
@export var item_category: ItemList = ItemList.SENTER

# Map data untuk menentukan String dan Texture
var item_data = {
	ItemList.SENTER: {"id": "flashlight", "tex": preload("res://assets/items/flashlight.jpeg")},
	ItemList.KUNCI: {"id": "key", "tex": preload("res://assets/items/key.jpeg")},
	ItemList.POTION: {"id": "potion", "tex": preload("res://assets/items/potion.jpeg")}
}

@onready var sprite = $Sprite2D

func _ready():
	# Otomatis ganti gambar saat muncul di map
	var data = item_data[item_category]
	sprite.texture = data["tex"]
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"): # Lebih aman pakai group daripada nama
		var item_id = item_data[item_category]["id"]
		
		if GameData.item_left == "none":
			GameData.item_left = item_id
			queue_free()
		elif GameData.item_right == "none":
			GameData.item_right = item_id
			queue_free()
		else:
			print("Tangan penuh! Buang dulu satu barang (Tekan 1 atau 2)")
