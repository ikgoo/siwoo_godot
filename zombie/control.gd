extends Control

@onready var text_edit = $TextEdit
var a = [4,5,6,7,1]
var times = 0
func _on_button_button_up():
	if text_edit.text:
		a.append(int(text_edit.text))
		

func _on_button_2_button_up():
	calcul()


func calcul():
	print(a)
	for c in range(len(a)):
		if c == 0:
			while a[c] > a[c+1]:
				a[c] = a[c] * 2
				times += 1
		elif c == len(a)-1:
			while a[c] < a[c-1]:
				a[c] = a[c] * 2
				times += 1
		else:
			while a[c] > a[c+1] and a[c] < a[c-1]:
				a[c] = a[c] * 2
				times += 1

				
		#[1,5,2,6]
	print(times)
	print(a)
