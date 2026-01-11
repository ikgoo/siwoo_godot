import React, { useState, useEffect, useCallback } from 'react';

const PetFollowSystemGuide = () => {
  const [activeMethod, setActiveMethod] = useState(3);
  const [showCode, setShowCode] = useState(false);
  const [playerPos, setPlayerPos] = useState({ x: 300, y: 180 });
  const [playerDir, setPlayerDir] = useState(1); // 1: 오른쪽, -1: 왼쪽
  const [prevPlayerX, setPrevPlayerX] = useState(300);
  const [pets, setPets] = useState([
    { x: 200, y: 180, visualDir: 1, targetDir: 1 },
    { x: 150, y: 180, visualDir: 1, targetDir: 1 },
    { x: 100, y: 180, visualDir: 1, targetDir: 1 },
  ]);
  const [history, setHistory] = useState([]);
  const [time, setTime] = useState(0);
  const [petCount, setPetCount] = useState(1);
  
  // 미세 조정 파라미터
  const [params, setParams] = useState({
    maxSpeed: 180,
    steeringForce: 6,
    arriveRadius: 60,
    stopRadius: 15,
    bobAmplitude: 6,
    bobFrequency: 2.5,
    flipSpeed: 8,
    followDistance: 45,
  });

  // 방향 전환 모드
  const [flipMode, setFlipMode] = useState('smooth'); // 'instant', 'smooth', 'squash'
  
  // 시뮬레이션 실행
  useEffect(() => {
    const interval = setInterval(() => {
      setTime(t => t + 0.05);
    }, 50);
    return () => clearInterval(interval);
  }, []);

  // 플레이어 이동 + 방향 전환 감지
  useEffect(() => {
    const centerX = 280;
    const centerY = 180;
    const radiusX = 120;
    const radiusY = 50;
    
    const newX = centerX + Math.cos(time * 0.8) * radiusX;
    const newY = centerY + Math.sin(time * 0.5) * radiusY;
    
    // 방향 전환 감지
    const deltaX = newX - prevPlayerX;
    if (Math.abs(deltaX) > 0.5) {
      setPlayerDir(deltaX > 0 ? 1 : -1);
    }
    setPrevPlayerX(newX);
    
    setPlayerPos({ x: newX, y: newY });
    
    // 히스토리 기록
    setHistory(prev => {
      const newHistory = [...prev, { x: newX, y: newY, dir: deltaX > 0 ? 1 : -1 }];
      if (newHistory.length > 60) newHistory.shift();
      return newHistory;
    });
  }, [time, prevPlayerX]);

  // 펫 움직임 업데이트
  useEffect(() => {
    setPets(prevPets => {
      return prevPets.map((pet, index) => {
        if (index >= petCount) return pet;
        
        // 타겟 위치 계산 (펫마다 다른 오프셋)
        let targetX, targetY, targetDir;
        
        if (activeMethod === 2 && history.length > 15 * (index + 1)) {
          // 히스토리 기반: 각 펫이 다른 시점의 위치를 따라감
          const historyIndex = Math.min(15 * (index + 1), history.length - 1);
          const histTarget = history[history.length - 1 - historyIndex];
          targetX = histTarget.x - params.followDistance * histTarget.dir;
          targetY = histTarget.y;
          targetDir = histTarget.dir;
        } else {
          // 다른 방식들: 앞 펫 또는 플레이어를 따라감
          const leader = index === 0 
            ? { x: playerPos.x, y: playerPos.y, dir: playerDir }
            : { x: prevPets[index - 1].x, y: prevPets[index - 1].y, dir: prevPets[index - 1].targetDir };
          
          targetX = leader.x - params.followDistance * leader.dir;
          targetY = leader.y;
          targetDir = leader.dir;
        }
        
        const dist = Math.hypot(targetX - pet.x, targetY - pet.y);
        let newX = pet.x;
        let newY = pet.y;
        
        // 이동 로직 (방식별)
        const delta = 0.05;
        switch(activeMethod) {
          case 0: // 단순 추적
            if (dist > params.stopRadius) {
              const speed = params.maxSpeed * delta;
              newX = pet.x + (targetX - pet.x) / dist * speed;
              newY = pet.y + (targetY - pet.y) / dist * speed;
            }
            break;
          
          case 1: // 스티어링 (Arrive)
            if (dist > params.stopRadius) {
              const speedFactor = Math.min(dist / params.arriveRadius, 1);
              const force = params.steeringForce * delta * speedFactor;
              newX = pet.x + (targetX - pet.x) * force;
              newY = pet.y + (targetY - pet.y) * force;
            }
            break;
          
          case 2: // 히스토리 기반
            if (dist > 5) {
              const force = 0.12;
              newX = pet.x + (targetX - pet.x) * force;
              newY = pet.y + (targetY - pet.y) * force;
            }
            break;
          
          case 3: // 스티어링 + 둥둥
          default:
            if (dist > params.stopRadius) {
              const speedFactor = Math.min(dist / params.arriveRadius, 1);
              const force = params.steeringForce * delta * speedFactor;
              newX = pet.x + (targetX - pet.x) * force;
              newY = pet.y + (targetY - pet.y) * force;
            }
            break;
        }
        
        // 방향 전환 처리
        let newVisualDir = pet.visualDir;
        const dirDiff = targetDir - pet.visualDir;
        
        if (Math.abs(dirDiff) > 0.01) {
          switch(flipMode) {
            case 'instant':
              newVisualDir = targetDir;
              break;
            case 'smooth':
              newVisualDir = pet.visualDir + dirDiff * params.flipSpeed * delta;
              break;
            case 'squash':
              // 스쿼시: 0으로 줄였다가 반대로
              if (Math.sign(pet.visualDir) !== Math.sign(targetDir) && Math.abs(pet.visualDir) > 0.1) {
                newVisualDir = pet.visualDir * (1 - params.flipSpeed * delta * 2);
              } else {
                newVisualDir = pet.visualDir + dirDiff * params.flipSpeed * delta;
              }
              break;
            default:
              newVisualDir = targetDir;
          }
        }
        
        return {
          x: newX,
          y: newY,
          visualDir: newVisualDir,
          targetDir: targetDir,
        };
      });
    });
  }, [playerPos, playerDir, activeMethod, history, params, flipMode, petCount]);

  const methods = [
    { name: "단순 추적", icon: "🤖", desc: "직선으로 따라감" },
    { name: "스티어링", icon: "🎯", desc: "부드러운 감속" },
    { name: "히스토리", icon: "🐍", desc: "경로 따라감" },
    { name: "스티어링+둥둥", icon: "✨", desc: "추천 조합" },
  ];

  const flipModes = [
    { id: 'instant', name: '즉시 반전', desc: '딱딱하지만 심플' },
    { id: 'smooth', name: '부드러운 전환', desc: '자연스러운 회전' },
    { id: 'squash', name: '스쿼시 효과', desc: '찌그러졌다 펴짐 (귀여움)' },
  ];

  const getBobOffset = (index) => {
    if (activeMethod !== 3) return 0;
    // 각 펫마다 약간 다른 위상
    return Math.sin(time * params.bobFrequency + index * 0.8) * params.bobAmplitude;
  };

  const getSquashScale = (pet) => {
    if (flipMode !== 'squash') return { x: 1, y: 1 };
    const absDir = Math.abs(pet.visualDir);
    if (absDir < 0.3) {
      // 찌그러질 때 Y축으로 늘어남
      return { x: Math.max(0.1, absDir), y: 1 + (1 - absDir) * 0.3 };
    }
    return { x: 1, y: 1 };
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-indigo-900 text-white p-4">
      <div className="max-w-6xl mx-auto">
        {/* 헤더 */}
        <div className="text-center mb-6">
          <h1 className="text-2xl font-bold mb-1">🎮 펫 팔로우 시스템 시뮬레이터</h1>
          <p className="text-slate-400 text-sm">실시간으로 파라미터를 조절하며 움직임 테스트</p>
        </div>

        <div className="grid lg:grid-cols-3 gap-4">
          {/* 시뮬레이션 영역 */}
          <div className="lg:col-span-2 space-y-4">
            {/* 방식 선택 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <div className="flex flex-wrap gap-2">
                {methods.map((method, idx) => (
                  <button
                    key={idx}
                    onClick={() => setActiveMethod(idx)}
                    className={`px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                      activeMethod === idx
                        ? 'bg-indigo-500 shadow-lg'
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`}
                  >
                    {method.icon} {method.name}
                  </button>
                ))}
              </div>
            </div>

            {/* 시뮬레이션 캔버스 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <div className="relative bg-slate-900 rounded-xl h-80 overflow-hidden border border-slate-700">
                {/* 그리드 배경 */}
                <svg className="absolute inset-0 w-full h-full opacity-10">
                  <defs>
                    <pattern id="grid" width="30" height="30" patternUnits="userSpaceOnUse">
                      <path d="M 30 0 L 0 0 0 30" fill="none" stroke="#94a3b8" strokeWidth="1"/>
                    </pattern>
                  </defs>
                  <rect width="100%" height="100%" fill="url(#grid)" />
                </svg>

                {/* 히스토리 경로 */}
                {activeMethod === 2 && history.length > 1 && (
                  <svg className="absolute inset-0 w-full h-full pointer-events-none">
                    <path
                      d={`M ${history.map(p => `${p.x},${p.y}`).join(' L ')}`}
                      fill="none"
                      stroke="#6366f1"
                      strokeWidth="2"
                      strokeDasharray="5 5"
                      opacity="0.4"
                    />
                  </svg>
                )}

                {/* 팔로우 포인트 표시 */}
                <div
                  className="absolute w-6 h-6 border-2 border-dashed border-yellow-400 rounded-full opacity-50"
                  style={{
                    left: playerPos.x - params.followDistance * playerDir - 12,
                    top: playerPos.y - 12,
                  }}
                />

                {/* 플레이어 */}
                <div
                  className="absolute transition-all duration-100 flex flex-col items-center"
                  style={{
                    left: playerPos.x - 20,
                    top: playerPos.y - 28,
                    transform: `scaleX(${playerDir})`,
                  }}
                >
                  <div className="text-4xl">🧙</div>
                </div>
                <div 
                  className="absolute text-xs text-slate-500"
                  style={{ left: playerPos.x - 20, top: playerPos.y + 15 }}
                >
                  Player
                </div>

                {/* 펫들 */}
                {pets.slice(0, petCount).map((pet, index) => {
                  const squash = getSquashScale(pet);
                  const bobY = getBobOffset(index);
                  return (
                    <React.Fragment key={index}>
                      <div
                        className="absolute transition-all duration-75 flex flex-col items-center"
                        style={{
                          left: pet.x - 16,
                          top: pet.y - 24 + bobY,
                          transform: `scaleX(${pet.visualDir > 0 ? squash.x : -squash.x}) scaleY(${squash.y})`,
                        }}
                      >
                        <div className="text-3xl">
                          {index === 0 ? '🧚' : index === 1 ? '🦋' : '🌟'}
                        </div>
                      </div>
                      <div 
                        className="absolute text-xs text-indigo-400"
                        style={{ left: pet.x - 12, top: pet.y + 12 + bobY }}
                      >
                        Pet {index + 1}
                      </div>
                    </React.Fragment>
                  );
                })}

                {/* 정보 표시 */}
                <div className="absolute top-3 left-3 bg-black/50 px-3 py-1.5 rounded-lg text-xs space-y-1">
                  <div>방식: {methods[activeMethod].icon} {methods[activeMethod].name}</div>
                  <div>펫 수: {petCount}마리</div>
                  <div>플레이어 방향: {playerDir > 0 ? '→ 오른쪽' : '← 왼쪽'}</div>
                </div>

                {/* 방향 전환 표시 */}
                <div className="absolute top-3 right-3 bg-black/50 px-3 py-1.5 rounded-lg text-xs">
                  방향전환: {flipModes.find(f => f.id === flipMode)?.name}
                </div>
              </div>
            </div>

            {/* 방향 전환 모드 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-3 flex items-center gap-2">
                <span>🔄</span> 방향 전환 방식
              </h3>
              <div className="grid grid-cols-3 gap-2">
                {flipModes.map((mode) => (
                  <button
                    key={mode.id}
                    onClick={() => setFlipMode(mode.id)}
                    className={`p-3 rounded-lg text-left transition-all ${
                      flipMode === mode.id
                        ? 'bg-indigo-600 ring-2 ring-indigo-400'
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`}
                  >
                    <div className="font-medium text-sm">{mode.name}</div>
                    <div className="text-xs text-slate-300 mt-1">{mode.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            {/* 노드 구조 다이어그램 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-3">🏗️ 노드 구조</h3>
              <div className="flex gap-4 text-xs overflow-x-auto">
                <div className="bg-slate-900 rounded-lg p-3 min-w-fit">
                  <div className="text-slate-400 mb-2">Player</div>
                  <div className="space-y-1">
                    <div className="bg-blue-900/50 px-2 py-1 rounded border-l-2 border-blue-500">CharacterBody2D</div>
                    <div className="ml-3 space-y-1">
                      <div className="bg-green-900/50 px-2 py-1 rounded border-l-2 border-green-500">Sprite2D</div>
                      <div className="ml-3">
                        <div className="bg-yellow-900/50 px-2 py-1 rounded border-l-2 border-yellow-500">
                          📍 FollowPoint
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="flex items-center text-2xl text-slate-600">→</div>
                <div className="bg-slate-900 rounded-lg p-3 min-w-fit">
                  <div className="text-slate-400 mb-2">Pet</div>
                  <div className="space-y-1">
                    <div className="bg-purple-900/50 px-2 py-1 rounded border-l-2 border-purple-500">CharacterBody2D</div>
                    <div className="ml-3 space-y-1">
                      <div className="bg-green-900/50 px-2 py-1 rounded border-l-2 border-green-500">
                        Sprite2D <span className="text-green-400">(둥둥+방향)</span>
                      </div>
                      <div className="bg-orange-900/50 px-2 py-1 rounded border-l-2 border-orange-500">AnimationPlayer</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* 파라미터 조절 패널 */}
          <div className="space-y-4">
            {/* 펫 개수 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-3">🧚 펫 개수</h3>
              <div className="flex gap-2">
                {[1, 2, 3].map(n => (
                  <button
                    key={n}
                    onClick={() => setPetCount(n)}
                    className={`flex-1 py-2 rounded-lg font-medium transition-all ${
                      petCount === n
                        ? 'bg-indigo-500'
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`}
                  >
                    {n}마리
                  </button>
                ))}
              </div>
            </div>

            {/* 파라미터 슬라이더들 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-4">🎛️ 파라미터 조절</h3>
              <div className="space-y-4">
                <ParamSlider
                  label="최대 속도"
                  param="maxSpeed"
                  value={params.maxSpeed}
                  min={50} max={400} step={10}
                  onChange={(v) => setParams(p => ({...p, maxSpeed: v}))}
                  leftLabel="느림 🐢"
                  rightLabel="빠름 🐇"
                />
                <ParamSlider
                  label="조향력 (민첩도)"
                  param="steeringForce"
                  value={params.steeringForce}
                  min={1} max={15} step={0.5}
                  onChange={(v) => setParams(p => ({...p, steeringForce: v}))}
                  leftLabel="나른"
                  rightLabel="민첩"
                />
                <ParamSlider
                  label="감속 시작 거리"
                  param="arriveRadius"
                  value={params.arriveRadius}
                  min={20} max={150} step={5}
                  onChange={(v) => setParams(p => ({...p, arriveRadius: v}))}
                  leftLabel="급정거"
                  rightLabel="서서히"
                />
                <ParamSlider
                  label="정지 거리"
                  param="stopRadius"
                  value={params.stopRadius}
                  min={5} max={50} step={1}
                  onChange={(v) => setParams(p => ({...p, stopRadius: v}))}
                  leftLabel="밀착"
                  rightLabel="거리유지"
                />
                <ParamSlider
                  label="팔로우 오프셋"
                  param="followDistance"
                  value={params.followDistance}
                  min={20} max={100} step={5}
                  onChange={(v) => setParams(p => ({...p, followDistance: v}))}
                  leftLabel="가까이"
                  rightLabel="멀리"
                />
                
                {activeMethod === 3 && (
                  <>
                    <div className="border-t border-slate-700 pt-4 mt-4">
                      <div className="text-xs text-indigo-400 mb-3">✨ 둥둥 효과</div>
                    </div>
                    <ParamSlider
                      label="떠다님 크기"
                      param="bobAmplitude"
                      value={params.bobAmplitude}
                      min={0} max={20} step={1}
                      onChange={(v) => setParams(p => ({...p, bobAmplitude: v}))}
                      leftLabel="미세"
                      rightLabel="큼"
                    />
                    <ParamSlider
                      label="떠다님 속도"
                      param="bobFrequency"
                      value={params.bobFrequency}
                      min={0.5} max={6} step={0.25}
                      onChange={(v) => setParams(p => ({...p, bobFrequency: v}))}
                      leftLabel="느긋"
                      rightLabel="팔랑"
                    />
                  </>
                )}

                <div className="border-t border-slate-700 pt-4 mt-4">
                  <div className="text-xs text-yellow-400 mb-3">🔄 방향 전환</div>
                </div>
                <ParamSlider
                  label="회전 속도"
                  param="flipSpeed"
                  value={params.flipSpeed}
                  min={2} max={20} step={1}
                  onChange={(v) => setParams(p => ({...p, flipSpeed: v}))}
                  leftLabel="천천히"
                  rightLabel="빠르게"
                />
              </div>
            </div>

            {/* 프리셋 */}
            <div className="bg-slate-800 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-3">⚡ 프리셋</h3>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => {
                    setParams({
                      maxSpeed: 180, steeringForce: 6, arriveRadius: 60,
                      stopRadius: 15, bobAmplitude: 6, bobFrequency: 2.5,
                      flipSpeed: 8, followDistance: 45
                    });
                    setActiveMethod(3);
                    setFlipMode('smooth');
                  }}
                  className="bg-indigo-600 hover:bg-indigo-500 p-2 rounded-lg text-xs"
                >
                  ✨ 귀여운 요정
                </button>
                <button
                  onClick={() => {
                    setParams({
                      maxSpeed: 280, steeringForce: 12, arriveRadius: 40,
                      stopRadius: 10, bobAmplitude: 2, bobFrequency: 4,
                      flipSpeed: 15, followDistance: 35
                    });
                    setActiveMethod(1);
                    setFlipMode('instant');
                  }}
                  className="bg-slate-700 hover:bg-slate-600 p-2 rounded-lg text-xs"
                >
                  🤖 민첩한 드론
                </button>
                <button
                  onClick={() => {
                    setParams({
                      maxSpeed: 120, steeringForce: 3, arriveRadius: 100,
                      stopRadius: 20, bobAmplitude: 10, bobFrequency: 1.5,
                      flipSpeed: 4, followDistance: 60
                    });
                    setActiveMethod(3);
                    setFlipMode('squash');
                  }}
                  className="bg-slate-700 hover:bg-slate-600 p-2 rounded-lg text-xs"
                >
                  🐌 느긋한 슬라임
                </button>
                <button
                  onClick={() => {
                    setParams({
                      maxSpeed: 200, steeringForce: 8, arriveRadius: 50,
                      stopRadius: 12, bobAmplitude: 0, bobFrequency: 0,
                      flipSpeed: 10, followDistance: 50
                    });
                    setActiveMethod(2);
                    setFlipMode('smooth');
                    setPetCount(3);
                  }}
                  className="bg-slate-700 hover:bg-slate-600 p-2 rounded-lg text-xs"
                >
                  🐍 파티 행렬
                </button>
              </div>
            </div>

            {/* 현재 값 표시 + 코드 보기 버튼 */}
            <div className="bg-slate-900 rounded-xl p-4 font-mono text-xs">
              <div className="text-slate-400 mb-2"># GDScript 참고값</div>
              <div className="text-green-400">max_speed = {params.maxSpeed}</div>
              <div className="text-green-400">steering_force = {params.steeringForce}</div>
              <div className="text-green-400">arrive_radius = {params.arriveRadius}</div>
              <div className="text-green-400">stop_radius = {params.stopRadius}</div>
              <div className="text-green-400">bob_amplitude = {params.bobAmplitude}</div>
              <div className="text-green-400">bob_frequency = {params.bobFrequency}</div>
              <div className="text-green-400">flip_speed = {params.flipSpeed}</div>
              
              <button
                onClick={() => setShowCode(true)}
                className="w-full mt-4 bg-indigo-600 hover:bg-indigo-500 py-2 rounded-lg font-sans text-sm font-medium"
              >
                📋 전체 GDScript 코드 보기
              </button>
            </div>
          </div>
        </div>

        {/* 코드 모달 */}
        {showCode && (
          <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
            <div className="bg-slate-800 rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
              <div className="flex justify-between items-center p-4 border-b border-slate-700">
                <h3 className="text-lg font-semibold">📄 Pet.gd - 전체 코드</h3>
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(generateGDScript(params, flipMode, petCount, activeMethod));
                      alert('클립보드에 복사되었습니다!');
                    }}
                    className="bg-green-600 hover:bg-green-500 px-4 py-2 rounded-lg text-sm"
                  >
                    📋 복사
                  </button>
                  <button
                    onClick={() => setShowCode(false)}
                    className="bg-slate-600 hover:bg-slate-500 px-4 py-2 rounded-lg text-sm"
                  >
                    ✕ 닫기
                  </button>
                </div>
              </div>
              <div className="overflow-auto p-4 flex-1">
                <pre className="text-xs text-green-400 whitespace-pre-wrap font-mono leading-relaxed">
                  {generateGDScript(params, flipMode, petCount, activeMethod)}
                </pre>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// GDScript 코드 생성 함수
const generateGDScript = (params, flipMode, petCount, activeMethod) => {
  const methodComment = {
    0: "단순 추적형",
    1: "스티어링 (Arrive)",
    2: "히스토리 기반 (경로 추적)",
    3: "스티어링 + 둥둥 효과 (추천)"
  };
  
  const flipModeComment = {
    'instant': "즉시 반전",
    'smooth': "부드러운 전환 (lerp)",
    'squash': "스쿼시 효과"
  };

  let code = `# ============================================
# Pet.gd - 펫 팔로우 시스템
# 방식: ${methodComment[activeMethod]}
# 방향전환: ${flipModeComment[flipMode]}
# 펫 개수: ${petCount}마리
# ============================================

extends CharacterBody2D

# === 플레이어 참조 ===
@export var player: CharacterBody2D

# === 시뮬레이터에서 설정한 값들 ===
@export var max_speed: float = ${params.maxSpeed}.0
@export var steering_force: float = ${params.steeringForce}
@export var arrive_radius: float = ${params.arriveRadius}.0
@export var stop_radius: float = ${params.stopRadius}.0
@export var bob_amplitude: float = ${params.bobAmplitude}.0
@export var bob_frequency: float = ${params.bobFrequency}
@export var flip_speed: float = ${params.flipSpeed}.0
@export var follow_distance: float = ${params.followDistance}.0

# === 내부 변수 ===
var time_elapsed: float = 0.0
var current_visual_scale_x: float = 1.0`;

  // 히스토리 기반일 경우 추가 변수
  if (activeMethod === 2) {
    code += `
var position_history: Array[Vector2] = []
var history_delay: int = 20  # 몇 프레임 뒤를 따라갈지`;
  }

  code += `

# === 노드 참조 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var follow_point: Marker2D = player.get_node("Sprite2D/FollowPoint")


func _physics_process(delta: float) -> void:
	time_elapsed += delta
	`;

  // 이동 로직 (방식별)
  if (activeMethod === 0) {
    // 단순 추적
    code += `
	# === 단순 추적 이동 ===
	var target = follow_point.global_position
	var distance = global_position.distance_to(target)
	
	velocity = Vector2.ZERO
	if distance > stop_radius:
		var direction = global_position.direction_to(target)
		velocity = direction * max_speed
	
	move_and_slide()`;
  } else if (activeMethod === 1) {
    // 스티어링
    code += `
	# === 스티어링 (Arrive) 이동 ===
	var target = follow_point.global_position
	var distance = global_position.distance_to(target)
	
	var desired_velocity = Vector2.ZERO
	if distance > stop_radius:
		var direction = global_position.direction_to(target)
		var speed_factor = clamp(distance / arrive_radius, 0.0, 1.0)
		desired_velocity = direction * max_speed * speed_factor
	
	var steering = (desired_velocity - velocity) * steering_force * delta
	velocity += steering
	
	move_and_slide()`;
  } else if (activeMethod === 2) {
    // 히스토리 기반
    code += `
	# === 히스토리 기반 이동 ===
	var player_pos = player.global_position
	
	# 위치 기록
	if position_history.is_empty() or player_pos.distance_to(position_history[-1]) > 5.0:
		position_history.append(player_pos)
	
	# 딜레이된 위치 따라가기
	if position_history.size() > history_delay:
		var target = position_history[0]
		position_history.remove_at(0)
		
		var direction = global_position.direction_to(target)
		velocity = direction * max_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()`;
  } else {
    // 스티어링 + 둥둥
    code += `
	# === 스티어링 (Arrive) 이동 ===
	var target = follow_point.global_position
	var distance = global_position.distance_to(target)
	
	var desired_velocity = Vector2.ZERO
	if distance > stop_radius:
		var direction = global_position.direction_to(target)
		var speed_factor = clamp(distance / arrive_radius, 0.0, 1.0)
		desired_velocity = direction * max_speed * speed_factor
	
	var steering = (desired_velocity - velocity) * steering_force * delta
	velocity += steering
	
	move_and_slide()
	
	# === 둥둥 효과 (Sprite에만 적용) ===
	var bob_offset = sin(time_elapsed * bob_frequency) * bob_amplitude
	sprite.position.y = bob_offset`;
  }

  // 방향 전환 로직
  code += `
	
	# === 방향 전환 처리 ===
	var target_scale_x = 1.0 if velocity.x >= 0 else -1.0
	`;

  if (flipMode === 'instant') {
    code += `
	# 즉시 반전
	if abs(velocity.x) > 5.0:
		sprite.scale.x = target_scale_x`;
  } else if (flipMode === 'smooth') {
    code += `
	# 부드러운 전환 (lerp)
	if abs(velocity.x) > 5.0:
		current_visual_scale_x = lerp(current_visual_scale_x, target_scale_x, flip_speed * delta)
	sprite.scale.x = current_visual_scale_x`;
  } else if (flipMode === 'squash') {
    code += `
	# 스쿼시 효과 (찌그러졌다 펴짐)
	if abs(velocity.x) > 5.0:
		if sign(current_visual_scale_x) != sign(target_scale_x) and abs(current_visual_scale_x) > 0.1:
			# 0으로 찌그러뜨리기
			current_visual_scale_x = lerp(current_visual_scale_x, 0.0, flip_speed * delta * 2)
			sprite.scale.y = 1.0 + (1.0 - abs(current_visual_scale_x)) * 0.3  # Y축 늘어남
		else:
			# 반대 방향으로 펴기
			current_visual_scale_x = lerp(current_visual_scale_x, target_scale_x, flip_speed * delta)
			sprite.scale.y = lerp(sprite.scale.y, 1.0, flip_speed * delta)
	sprite.scale.x = current_visual_scale_x if abs(current_visual_scale_x) > 0.1 else sign(target_scale_x) * 0.1`;
  }

  // 애니메이션 처리
  code += `
	
	# === 애니메이션 ===
	if velocity.length() > 10:
		anim.play("fly")
	else:
		anim.play("idle")
`;

  // 다중 펫 매니저 (2마리 이상일 때)
  if (petCount > 1) {
    code += `

# ============================================
# PetManager.gd - 다중 펫 관리
# Player 노드에 이 스크립트를 붙이거나 별도 노드로 관리
# ============================================

# extends Node2D
# 
# @export var player: CharacterBody2D
# @export var pet_scene: PackedScene  # Pet.tscn
# @export var pet_count: int = ${petCount}
# 
# var pets: Array[CharacterBody2D] = []
# 
# func _ready() -> void:
# 	for i in range(pet_count):
# 		var pet = pet_scene.instantiate() as CharacterBody2D
# 		add_child(pet)
# 		
# 		# 첫 번째 펫은 플레이어를, 나머지는 앞 펫을 따라감
# 		if i == 0:
# 			pet.player = player
# 		else:
# 			pet.player = pets[i - 1]
# 		
# 		# 각 펫마다 약간 다른 둥둥 위상
# 		pet.time_elapsed = i * 0.5
# 		
# 		pets.append(pet)
`;
  }

  return code;
};


// 슬라이더 컴포넌트
const ParamSlider = ({ label, param, value, min, max, step, onChange, leftLabel, rightLabel }) => {
  return (
    <div>
      <div className="flex justify-between text-xs mb-1">
        <span className="text-slate-300">{label}</span>
        <span className="text-indigo-400 font-mono">{value}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
        className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
      />
      <div className="flex justify-between text-xs text-slate-500 mt-1">
        <span>{leftLabel}</span>
        <span>{rightLabel}</span>
      </div>
    </div>
  );
};

export default PetFollowSystemGuide;
