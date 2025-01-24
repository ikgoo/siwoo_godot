import pygame
import sys
import random
import math

# 초기화
pygame.init()

# 화면 설정
WINDOW_WIDTH = 1200
WINDOW_HEIGHT = 800
PIXEL_SIZE = 30

# 색상 정의
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)

class Player:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.color = RED
        self.speed = PIXEL_SIZE // 2  # 이동 속도를 절반으로 줄임
        self.size = PIXEL_SIZE
        self.health = 10000000000000000000
        self.attack_cooldown = 0
        self.attack_range = PIXEL_SIZE * 10000  # 공격 범위 증가
        self.is_attacking = False
        self.target_x = x  # 마우스 이동을 위한 목표 위치
        self.target_y = y

    def move_to_mouse(self):
        # 현재 위치와 목표 위치 간의 거리 계산
        dx = self.target_x - self.x
        dy = self.target_y - self.y
        dist = math.sqrt(dx**2 + dy**2)
        
        if dist > self.speed:  # 목표 지점이 이동 거리보다 멀 경우
            # 정규화된 방향 벡터 계산
            dx = dx / dist * self.speed
            dy = dy / dist * self.speed
            
            # 새로운 위치 계산
            new_x = self.x + dx
            new_y = self.y + dy
            
            # 화면 경계 확인
            if 0 <= new_x <= WINDOW_WIDTH - self.size:
                self.x = new_x
            if 0 <= new_y <= WINDOW_HEIGHT - self.size:
                self.y = new_y

    def attack(self):
        if self.attack_cooldown <= 0:
            self.is_attacking = True
            self.attack_cooldown = 30
            return True
        return False

    def update(self):
        if self.attack_cooldown > 0:
            self.attack_cooldown -= 1
        if self.attack_cooldown <= 25:
            self.is_attacking = False
        self.move_to_mouse()

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))
        # 체력바 그리기
        pygame.draw.rect(screen, RED, (self.x, self.y - 10, self.size, 5))
        pygame.draw.rect(screen, GREEN, (self.x, self.y - 10, self.size * (self.health/100), 5))
        # 공격 범위 표시
        if self.is_attacking:
            pygame.draw.circle(screen, YELLOW, 
                             (self.x + self.size//2, self.y + self.size//2), 
                             self.attack_range, 2)

class Enemy:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.color = BLUE
        self.speed = PIXEL_SIZE // 6
        self.size = PIXEL_SIZE
        self.health = 100
        self.damage_range = PIXEL_SIZE * 1.5
        self.damage = 3.5

    def move_towards_player(self, player):
        dx = player.x - self.x
        dy = player.y - self.y
        dist = math.sqrt(dx**2 + dy**2)
        if dist != 0:
            dx = dx / dist * self.speed
            dy = dy / dist * self.speed
            self.x += dx
            self.y += dy

    def deal_damage(self, player):
        dx = player.x - self.x
        dy = player.y - self.y
        dist = math.sqrt(dx**2 + dy**2)
        if dist < self.damage_range:
            player.health -= self.damage
            return True
        return False

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))
        pygame.draw.rect(screen, RED, (self.x, self.y - 10, self.size, 5))
        pygame.draw.rect(screen, GREEN, (self.x, self.y - 10, self.size * (self.health/100), 5))

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption("Pixel Combat Game")
        self.clock = pygame.time.Clock()
        self.player = Player(WINDOW_WIDTH//2, WINDOW_HEIGHT//2)
        self.enemies = [Enemy(random.randint(0, WINDOW_WIDTH-PIXEL_SIZE),
                            random.randint(0, WINDOW_HEIGHT-PIXEL_SIZE))
                       for _ in range(5)]
        self.running = True
        self.score = 0
        self.font = pygame.font.Font(None, 36)

    def handle_input(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # 좌클릭
                    self.handle_attack()
                elif event.button == 3:  # 우클릭
                    # 마우스 우클릭 위치로 이동 목표 설정
                    self.player.target_x, self.player.target_y = pygame.mouse.get_pos()
                    # 플레이어 크기를 고려한 위치 조정
                    self.player.target_x -= self.player.size // 2
                    self.player.target_y -= self.player.size // 2

    def handle_attack(self):
        if self.player.attack():
            for enemy in self.enemies[:]:
                dx = enemy.x - self.player.x
                dy = enemy.y - self.player.y
                dist = math.sqrt(dx**2 + dy**2)
                if dist < self.player.attack_range:
                    enemy.health -= 100
                    if enemy.health <= 0:
                        self.enemies.remove(enemy)
                        self.score += 10000000000000000000000000000000000000000
                        self.enemies.append(Enemy(
                            random.randint(0, WINDOW_WIDTH-PIXEL_SIZE),
                            random.randint(0, WINDOW_HEIGHT-PIXEL_SIZE)
                        ))

    def update(self):
        self.player.update()
        
        for enemy in self.enemies:
            enemy.move_towards_player(self.player)
            if enemy.deal_damage(self.player):
                enemy.color = RED
            else:
                enemy.color = BLUE
                
        if self.player.health <= 0:
            self.show_game_over()
            self.running = False

    def draw(self):
        self.screen.fill(BLACK)
        
        for x in range(0, WINDOW_WIDTH, PIXEL_SIZE):
            pygame.draw.line(self.screen, WHITE, (x, 0), (x, WINDOW_HEIGHT), 1)
        for y in range(0, WINDOW_HEIGHT, PIXEL_SIZE):
            pygame.draw.line(self.screen, WHITE, (0, y), (WINDOW_WIDTH, y), 1)
        
        self.player.draw(self.screen)
        for enemy in self.enemies:
            enemy.draw(self.screen)
            
        score_text = self.font.render(f'Score: {self.score}', True, WHITE)
        self.screen.blit(score_text, (10, 10))

        pygame.display.flip()

    def show_game_over(self):
        text = self.font.render(f'Game Over! Final Score: {self.score}', True, WHITE)
        text_rect = text.get_rect(center=(WINDOW_WIDTH/2, WINDOW_HEIGHT/2))
        self.screen.blit(text, text_rect)
        pygame.display.flip()
        pygame.time.wait(2000)

    def run(self):
        while self.running:
            self.handle_input()
            self.update()
            self.draw()
            self.clock.tick(60)

        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    game = Game()
    game.run()