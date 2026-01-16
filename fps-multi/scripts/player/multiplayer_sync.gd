extends MultiplayerSynchronizer

## 플레이어 멀티플레이어 동기화
## 위치, 회전, 카메라 방향 동기화

func _ready():
	# 동기화 설정
	var config = SceneReplicationConfig.new()
	
	# 플레이어 위치 동기화
	config.add_property(NodePath("../:position"))
	config.property_set_replication_mode(NodePath("../:position"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	
	# 플레이어 회전 동기화 (Y축만)
	config.add_property(NodePath("../:rotation:y"))
	config.property_set_replication_mode(NodePath("../:rotation:y"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	
	# 카메라 컨트롤러 회전 동기화
	config.add_property(NodePath("../CameraController:rotation"))
	config.property_set_replication_mode(NodePath("../CameraController:rotation"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	
	replication_config = config

