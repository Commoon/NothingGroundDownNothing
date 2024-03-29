tool
extends Interactable

signal updated

export var TEXT = "" setget set_text
export var NORMAL_COLOR = Color.white
export var SELECTED_COLOR = Color.red
export var HINT_COLOR = Color.purple
export var EFFECT_PERIOD = 0.8
export var HINT_PERIOD = 5.0

onready var text = $Text
onready var collision_shape = $CollisionShape2D

var word = ""
var index = 0
var wait_to_update = -1
var effect_status = -1
var hinting = false
var hinting_timer = 0.0


func update():
    var vec = text.rect_size / 2
    (collision_shape.shape as RectangleShape2D).extents = vec / 2
    collision_shape.position = vec
    wait_to_update = -1
    text.visible_characters = 0
    emit_signal("updated")


func update_effect():
    if effect_status == -1:
        text.modulate = NORMAL_COLOR
    else:
        text.modulate = NORMAL_COLOR.linear_interpolate(
            SELECTED_COLOR if selected else HINT_COLOR,
            (1 - abs(effect_status * 2 - EFFECT_PERIOD) / EFFECT_PERIOD)
        )


func _process(delta):
    if text == null:
        return
    if wait_to_update > 0:
        wait_to_update -= 1
    elif wait_to_update == 0:
        update()
    if text.visible_characters < text.text.length():
        return
    if can_interact(null):
        hinting_timer += delta
        if hinting_timer >= HINT_PERIOD:
            hinting = true
            hinting_timer = 0
    if selected or hinting:
        effect_status = 0 if effect_status < 0 else effect_status + delta
        if effect_status >= EFFECT_PERIOD:
            if selected:
                effect_status -= EFFECT_PERIOD
            else:
                hinting = false
                effect_status = -1
        update_effect()
    elif effect_status >= 0:
        effect_status = -1
        update_effect()


func _ready():
    set_text(TEXT)


func set_text(value):
    TEXT = value
    if text != null:
        text.text = value
        text.hide()
        text.show()
        wait_to_update = 5
    word = Utils.strip_word(TEXT)
    item_name = "word-%s" % word


func can_interact(player):
    var current_words = Game.current_stage.current_words
    return text.visible_characters == text.text.length() and \
        current_words[-1][-1].to_lower() == word[0].to_lower() and \
        current_words.find(word) < 0



func interact(player):
    Game.current_stage.add_word(word)
    .interact(player)
