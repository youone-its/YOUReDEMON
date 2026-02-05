# GameProgress.gd
extends Node

# Layer yang sedang aktif saat ini
var current_layer: int = 1

func advance_layer():
	current_layer += 1
	print("Progress: Sekarang masuk ke Layer ", current_layer)
