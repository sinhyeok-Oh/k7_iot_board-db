# DROP DATABASE IF EXISTS `board_v1`;
CREATE DATABASE IF NOT EXISTS `board_v1`
	CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;
USE `board_v1`;

SET NAMES utf8mb4;				# 클라이언트와 MySQL 서버 간의 문자 인코딩 설정
SET FOREIGN_KEY_CHECKS = 0;		# 외래 키 제약 조건 검사를 일시적으로 끄는 설정

# === 기존 테이블 제거 === #
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS board_likes;
DROP TABLE IF EXISTS board_drafts;
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS board_categories;

DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;

# === USERS (사용자) === #

CREATE TABLE users (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    username VARCHAR(50) NOT NULL COMMENT '로그인 ID',
    password VARCHAR(255) NOT NULL COMMENT 'Bcrypt 암호화 비밀번호',
    email VARCHAR(255) NOT NULL COMMENT '사용자 이메일',
    nickname VARCHAR(50) NOT NULL COMMENT '닉네임',
    
    gender VARCHAR(10) COMMENT '성별',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    CONSTRAINT `uk_users_username` UNIQUE(username),
    CONSTRAINT `uk_users_email` UNIQUE(email),
    CONSTRAINT `uk_users_nickname` UNIQUE(nickname),
    CONSTRAINT `chk_users_gender` CHECK(gender IN ('MALE', 'FEMALE', 'OTHER', 'NONE'))
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '사용자 기본 정보 테이블';

-- ---- Seed: USERS (15명)
INSERT INTO users (username, password, email, nickname, gender, created_at, updated_at) VALUES
('admin', 'encrypted_pw', 'admin@site.com', '관리자', 'MALE', NOW(), NOW()),
('user01', 'pw01', 'user01@mail.com', '곰돌이1', 'MALE', NOW(), NOW()),
('user02', 'pw02', 'user02@mail.com', '곰돌이2', 'FEMALE', NOW(), NOW()),
('user03', 'pw03', 'user03@mail.com', '토끼1', 'MALE', NOW(), NOW()),
('user04', 'pw04', 'user04@mail.com', '토끼2', 'FEMALE', NOW(), NOW()),
('user05', 'pw05', 'user05@mail.com', '기린1', 'MALE', NOW(), NOW()),
('user06', 'pw06', 'user06@mail.com', '기린2', 'FEMALE', NOW(), NOW()),
('user07', 'pw07', 'user07@mail.com', '사자1', 'MALE', NOW(), NOW()),
('user08', 'pw08', 'user08@mail.com', '사자2', 'FEMALE', NOW(), NOW()),
('user09', 'pw09', 'user09@mail.com', '판다1', 'MALE', NOW(), NOW()),
('user10', 'pw10', 'user10@mail.com', '판다2', 'FEMALE', NOW(), NOW()),
('user11', 'pw11', 'user11@mail.com', '부엉이1', 'MALE', NOW(), NOW()),
('user12', 'pw12', 'user12@mail.com', '부엉이2', 'FEMALE', NOW(), NOW()),
('user13', 'pw13', 'user13@mail.com', '하마1', 'MALE', NOW(), NOW()),
('user14', 'pw14', 'user14@mail.com', '하마2', 'FEMALE', NOW(), NOW());

# === ROLES (권한) === #
CREATE TABLE roles (
	role_name VARCHAR(30) PRIMARY KEY,
    CONSTRAINT `chk_roles_role_name` CHECK(role_name IN ('ROLE_USER', 'ROLE_ADMIN', 'ROLE_MANAGER'))
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '사용자 권한 테이블';
    
INSERT INTO roles VALUES ('ROLE_ADMIN'), ('ROLE_MANAGER'), ('ROLE_USER');

# === USER_ROLES (유저-권한 매핑) === #
CREATE TABLE user_roles (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_name VARCHAR(30) NOT NULL,
    
    UNIQUE KEY `uk_user_roles_user_id_role_name` (user_id, role_name),
    INDEX `idx_user_roles_user_id` (user_id),
    INDEX `idx_user_roles_role_name` (role_name),
    
    CONSTRAINT `fk_user_role_user` FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT `fk_user_role_role` FOREIGN KEY (role_name) REFERENCES roles(role_name)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '유저-권한 매핑 테이블';
    
-- ---- Seed USER_ROLES
INSERT INTO user_roles (user_id, role_name) VALUES
(1, 'ROLE_ADMIN'),
(2, 'ROLE_MANAGER'),
(3, 'ROLE_MANAGER'),
(4, 'ROLE_MANAGER'),
(5, 'ROLE_MANAGER'),
(6, 'ROLE_MANAGER'),
(7, 'ROLE_MANAGER'),
(8, 'ROLE_USER'),
(9, 'ROLE_USER'),
(10, 'ROLE_USER'),
(11, 'ROLE_USER'),
(12, 'ROLE_USER'),
(13, 'ROLE_USER'),
(14, 'ROLE_USER'),
(15, 'ROLE_USER');

# === REFRESH TOKENS (1:1 관계) === #
CREATE TABLE refresh_tokens (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '사용자 ID',
    token VARCHAR(350) NOT NULL COMMENT '리프레시 토큰 값',
    expiry DATETIME(6) NOT NULL COMMENT '만료 시간',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    INDEX `idx_refresh_token_user_id` (user_id),
    
    CONSTRAINT `fk_refresh_token_user` FOREIGN KEY (user_id) REFERENCES users(id)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '리프레시 토큰 저장 테이블';
    
-- ---- Seed Refresh Tokens (5개)
INSERT INTO refresh_tokens (user_id, token, expiry, created_at, updated_at)
VALUES
(1, 'sampletoken_admin', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW(), NOW()),
(2, 'sampletoken_u1', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW(), NOW()),
(3, 'sampletoken_u2', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW(), NOW()),
(4, 'sampletoken_u3', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW(), NOW()),
(5, 'sampletoken_u4', DATE_ADD(NOW(), INTERVAL 30 DAY), NOW(), NOW());

# === Board / Category (게시판 / 게시판 카테고리) === #
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS board_categories;

CREATE TABLE board_categories (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL COMMENT '카테고리명',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    CONSTRAINT `uk_board_category_name` UNIQUE (name)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시판 카테고리';

-- ---- Seed Categories (10개)
INSERT INTO board_categories (name, created_at, updated_at) VALUES
('공지사항', NOW(), NOW()),
('자유게시판', NOW(), NOW()),
('질문답변', NOW(), NOW()),
('유머', NOW(), NOW()),
('사진', NOW(), NOW()),
('정보공유', NOW(), NOW()),
('프로젝트', NOW(), NOW()),
('Spring', NOW(), NOW()),
('JavaScript', NOW(), NOW()),
('DB/SQL', NOW(), NOW());

CREATE TABLE boards (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    title VARCHAR(150) NOT NULL COMMENT '글 제목',
    content LONGTEXT NOT NULL COMMENT '글 제목',
    
    view_count BIGINT NOT NULL DEFAULT 0 COMMENT '조회수',
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE COMMENT '상단 고정 여부',
    
    user_id BIGINT NOT NULL COMMENT '작성자',
    category_id BIGINT NOT NULL COMMENT '카테고리 ID',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    INDEX `idx_boards_created_at` (created_at),
    INDEX `idx_boards_updated_at` (updated_at),
    
    CONSTRAINT `fk_board_user` FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT `fk_board_category` FOREIGN KEY (category_id) REFERENCES board_categories(id)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시글';
    
-- ---- Seed Boards (15개)
INSERT INTO boards (title, content, view_count, is_pinned, user_id, category_id, created_at, updated_at)
VALUES
('공지: 서버 유지보수 안내', '내일 새벽 서버 점검합니다.', 100, TRUE, 1, 1, NOW(), NOW()),
('첫 번째 자유게시글', '가입했습니다.', 12, FALSE, 2, 2, NOW(), NOW()),
('스프링 질문입니다.', 'DI와 IOC가 뭔가요?', 54, FALSE, 3, 8, NOW(), NOW()),
('오늘 찍은 사진입니다.', '부산 바다 사진', 77, FALSE, 4, 5, NOW(), NOW()),
('유머 모음집', '웃긴 글 모음', 120, FALSE, 5, 4, NOW(), NOW()),
('프로젝트 제안', '같이 할 사람?', 18, FALSE, 6, 7, NOW(), NOW()),
('자바스크립트 질문', 'this 바인딩?', 44, FALSE, 7, 9, NOW(), NOW()),
('DB optimization', '인덱스 팁 알려주세요', 65, FALSE, 8, 10, NOW(), NOW()),
('운동 정보 공유', '3대 500 도전', 12, FALSE, 9, 6, NOW(), NOW()),
('자유글 테스트1', '내용입니다', 0, FALSE, 10, 2, NOW(), NOW()),
('자유글 테스트2', '내용입니다', 0, FALSE, 11, 2, NOW(), NOW()),
('자유글 테스트3', '내용입니다', 0, FALSE, 12, 2, NOW(), NOW()),
('유머1', 'ㅋㅋㅋㅋ', 22, FALSE, 13, 4, NOW(), NOW()),
('유머2', '하하하', 30, FALSE, 14, 4, NOW(), NOW()),
('스프링 정보', 'Bean Scope 정리', 10, FALSE, 15, 8, NOW(), NOW());
    
# === Comment (게시글 댓글) === #
CREATE TABLE comments (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    content LONGTEXT NOT NULL COMMENT '댓글 내용',
    
    board_id BIGINT NOT NULL COMMENT '게시글 ID',
    user_id BIGINT NOT NULL COMMENT '작성자 ID',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    INDEX `idx_comments_board_id` (board_id),
    INDEX `idx_comments_user_id` (user_id),
    
    CONSTRAINT `fk_comment_board` FOREIGN KEY (board_id) REFERENCES boards(id),
    CONSTRAINT `fk_comment_user` FOREIGN KEY (user_id) REFERENCES users(id)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시글 댓글';

-- ---- Seed Comments (15개)
INSERT INTO comments (content, board_id, user_id, created_at, updated_at)
VALUES
('좋은 정보 감사합니다!', 1, 2, NOW(), NOW()),
('환영합니다!', 2, 3, NOW(), NOW()),
('저도 궁금합니다.', 3, 4, NOW(), NOW()),
('사진 멋져요', 4, 5, NOW(), NOW()),
('ㅋㅋㅋㅋㅋ', 5, 6, NOW(), NOW()),
('저요!', 6, 7, NOW(), NOW()),
('this 어렵죠', 7, 8, NOW(), NOW()),
('좋은 설명 감사합니다', 8, 9, NOW(), NOW()),
('화이팅!', 9, 10, NOW(), NOW()),
('댓글 테스트1', 10, 11, NOW(), NOW()),
('댓글 테스트2', 11, 12, NOW(), NOW()),
('댓글 테스트3', 12, 13, NOW(), NOW()),
('웃기네요', 13, 14, NOW(), NOW()),
('ㅋㅋ', 14, 15, NOW(), NOW()),
('유용한 글이네요', 15, 1, NOW(), NOW());
    
# === BoardLike (게시글 좋아요) === #
CREATE TABLE board_likes (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    board_id BIGINT NOT NULL COMMENT '게시글 ID',
    user_id BIGINT NOT NULL COMMENT '작성자 ID',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    UNIQUE KEY `uk_board_like_user` (board_id, user_id),
    INDEX `idx_board_like_board` (board_id),
    INDEX `idx_board_like_user` (user_id),
    
    CONSTRAINT `fk_board_like_board` FOREIGN KEY (board_id) REFERENCES boards(id),
    CONSTRAINT `fk_board_like_user` FOREIGN KEY (user_id) REFERENCES users(id)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시글 좋아요';
    
-- ---- Seed Likes (15개)
INSERT INTO board_likes (board_id, user_id, created_at, updated_at)
VALUES
(1, 2, NOW(), NOW()),
(1, 3, NOW(), NOW()),
(2, 4, NOW(), NOW()),
(3, 5, NOW(), NOW()),
(4, 6, NOW(), NOW()),
(5, 7, NOW(), NOW()),
(6, 8, NOW(), NOW()),
(7, 9, NOW(), NOW()),
(8, 10, NOW(), NOW()),
(9, 11, NOW(), NOW()),
(10, 12, NOW(), NOW()),
(11, 13, NOW(), NOW()),
(12, 14, NOW(), NOW()),
(13, 15, NOW(), NOW()),
(14, 1, NOW(), NOW());

# === BoardDraft (게시글 임시저장) === #
CREATE TABLE board_drafts (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    title VARCHAR(150) NULL COMMENT '임시 제목',
    content LONGTEXT NULL COMMENT '임시 내용',
    
    user_id BIGINT NOT NULL,   
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    INDEX `idx_board_drafts_user_id` (user_id),
    INDEX `idx_board_drafts_updated_at` (updated_at),
    
    CONSTRAINT `fk_board_draft_user` FOREIGN KEY (user_id) REFERENCES users(id)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시글 임시 저장';

-- ---- Seed Drafts (10개)
INSERT INTO board_drafts (title, content, user_id, created_at, updated_at)
VALUES
('임시글1', '아직 작성중', 2, NOW(), NOW()),
('임시글2', '임시 내용', 3, NOW(), NOW()),
('임시글3', '내용 적는중', 4, NOW(), NOW()),
('임시글4', '나중에 마무리', 5, NOW(), NOW()),
('임시글5', '임시', 6, NOW(), NOW()),
('임시글6', '테스트', 7, NOW(), NOW()),
('임시글7', '작성중', 8, NOW(), NOW()),
('임시글8', '초안입니다', 9, NOW(), NOW()),
('임시글9', '메모', 10, NOW(), NOW()),
('임시글10', '초안 테스트', 11, NOW(), NOW());

SET FOREIGN_KEY_CHECKS = 1;