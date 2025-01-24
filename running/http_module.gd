extends Node

const BASE_URL = "https://jetflying.noligo.co.kr/rankings"
const BEARER_TOKEN = "6955c8c7-299f-47e2-a921-70b5ddf03f4a"

# 랭킹 정보를 가져오는 함수
func get_rankings() -> Variant:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = PackedStringArray([
		"Authorization: Bearer " + BEARER_TOKEN,
		"Content-Type: application/json"
	])
	
	var error = http_request.request(BASE_URL, headers)
	if error != OK:
		var error_msg = "랭킹 정보를 가져오는데 실패했습니다. 에러 코드: " + str(error)
		push_error(error_msg)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "네트워크 오류가 발생했습니다. 결과 코드: " + str(result)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	if response_code != 200:
		var error_msg = "서버 오류가 발생했습니다. 상태 코드: " + str(response_code)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	return json

# 랭킹 정보 저장하는 함수
func save_ranking(username: String, score: int) -> Variant:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var headers = PackedStringArray([
		"Authorization: Bearer " + BEARER_TOKEN,
		"Content-Type: application/json"
	])
	
	var body = JSON.stringify({
		"username": username,
		"score": score
	})
	
	var error = http_request.request(BASE_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		var error_msg = "랭킹 정보를 저장하는데 실패했습니다. 에러 코드: " + str(error)
		push_error(error_msg)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var response_body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "네트워크 오류가 발생했습니다. 결과 코드: " + str(result)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	if response_code != 200:
		var error_msg = "서버 오류가 발생했습니다. 상태 코드: " + str(response_code)
		print("[랭킹 서비스 오류] ", error_msg)
		return null
		
	var json = JSON.parse_string(response_body.get_string_from_utf8())
	return json
