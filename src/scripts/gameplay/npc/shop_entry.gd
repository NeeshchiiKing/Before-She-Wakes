class_name ShopEntry
extends Resource

@export var item: Resource       # e.g. pouch.tres
@export var currency: Resource   # e.g. paper.tres
@export var price: int = 10

@export var sold_out_flag: String = ""   # leave empty = unlimited stock
