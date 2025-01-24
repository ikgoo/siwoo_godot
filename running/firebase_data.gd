extends Node2D

signal data_loaded(rank_data)

const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/siwoo-b39ff/databases/(default)/documents"
const API_KEY = "AIzaSyA8gYKJMzXXvsLRplZe8ADMYhwZ2GxfY_M"
const MAX_RANKS = 10

var current_rankings: Array = []

#func _ready():
	#load_data("jet_flying", "high_score")

func _process(delta):
	pass

# 데이터 로드
func load_data(collection: String, document_id: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_completed)
	
	var url = "%s/%s/%s?key=%s" % [FIRESTORE_URL, collection, document_id, API_KEY]
	http.request(url)
	
# 로드 완료 콜백
func _on_load_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray,) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		#print("받은 데이터: ", json)
		
		if json.has("fields") and json.fields.has("rankings"):
			var rankings_data = json.fields.rankings.arrayValue
			if rankings_data.has("values"):
				current_rankings.clear()
				for rank_data in rankings_data.values:
					var rank_fields = rank_data.mapValue.fields
					var rank_entry = {
						"name": rank_fields.name.stringValue,
						"score": int(rank_fields.score.integerValue)
					}
					current_rankings.append(rank_entry)
				#print("현재 랭킹: ", current_rankings)
				
				emit_signal("data_loaded", current_rankings)
			#else:
				##print("랭킹이 비어있습니다. 초기화합니다.")
				#current_rankings.clear()
				
		#else:
			#print("새로운 랭킹 데이터를 생성합니다.")
			
			emit_signal("data_loaded", current_rankings)
	#else:
		#print("로드 실패: ", response_code)
	
	var http = get_node_or_null("HTTPRequest")
	if http:
		http.queue_free()

# 데이터 저장
func save_data(collection: String, document_id: String, data: Dictionary) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_save_completed)
	
	var url = "%s/%s/%s?key=%s" % [FIRESTORE_URL, collection, document_id, API_KEY]
	
	# Firestore 형식으로 데이터 변환
	var rankings_array = []
	for rank in data.rankings:
		rankings_array.append({
			"mapValue": {
				"fields": {
					"name": {"stringValue": rank.name},
					"score": {"integerValue": str(rank.score)}  # 정수는 문자열로 변환
				}
			}
		})
	
	var body = JSON.stringify({
		"fields": {
			"rankings": {
				"arrayValue": {
					"values": rankings_array
				}
			}
		}
	})
	
	var headers = ["Content-Type: application/json"]
	#print("저장할 데이터: ", body)
	
	http.request(url, headers, HTTPClient.METHOD_PATCH, body)

# 저장 완료 콜백
func _on_save_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		#print("저장 성공!")
		#print("저장된 데이터: ", json)
	#else:
		##print("저장 실패: ", response_code)
		##print("에러: ", body.get_string_from_utf8())
	
	var http = get_node_or_null("HTTPRequest")
	if http:
		http.queue_free()
	

# 새로운 점수 확인 및 랭킹 업데이트
func check_and_update_ranking(player_name: String, new_score: int):
	
	var inserted = false
	var new_entry = {"name": player_name, "score": new_score}
	
	# 빈 랭킹이면 바로 추가
	if current_rankings.is_empty():
		current_rankings.append(new_entry)
		save_data("jet_flying", "high_score", {"rankings": current_rankings})
		return false
		
	for i in range(current_rankings.size()):
		if new_score > current_rankings[i].score:
			if i > 8:
				return true
			current_rankings.insert(i, new_entry)
			inserted = true
			break
	
	if !inserted and current_rankings.size() < MAX_RANKS:
		current_rankings.append(new_entry)
	
	if current_rankings.size() > MAX_RANKS:
		current_rankings.resize(MAX_RANKS)
	
	save_data("jet_flying", "high_score", {"rankings": current_rankings})
	return false
