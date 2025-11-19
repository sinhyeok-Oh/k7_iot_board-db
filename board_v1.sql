DROP DATABASE IF EXISTS `board_v1`; 
CREATE DATABASE IF NOT EXISTS `board_v1`
	CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;
USE `board_v1`;

SET NAMES utf8mb4;				# 클라이언트와 MySQL 서버 간의 문자 인코딩 설정
SET FOREIGN_KEY_CHECKS = 0;		# 외래 키 제약 조건 검사를 일시적으로 끄는 설정

# === 기존 테이블 제거 === #
DROP TABLE IF EXISTS post_files;
DROP TABLE IF EXISTS file_infos;

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS board_likes;
DROP TABLE IF EXISTS board_drafts;
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS board_categories;

DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;

# === FILE_INFO (파일 정보 테이블) === #
CREATE TABLE file_infos (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    original_name VARCHAR(255) NOT NULL COMMENT '원본 파일명',
    stored_name VARCHAR(255) NOT NULL COMMENT 'UUID가 적용된 파일명',
    content_type VARCHAR(255),
    file_size BIGINT,
    file_path VARCHAR(255) NOT NULL COMMENT '서버 내 실제 경로',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '파일 정보 테이블';

# === USERS (사용자) === #

CREATE TABLE users (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    username VARCHAR(50) NOT NULL COMMENT '로그인 ID',
    password VARCHAR(255) NOT NULL COMMENT 'Bcrypt 암호화 비밀번호',
    email VARCHAR(255) NOT NULL COMMENT '사용자 이메일',
    nickname VARCHAR(50) NOT NULL COMMENT '닉네임',
    
    gender VARCHAR(10) COMMENT '성별',
    profile_file_id BIGINT NULL COMMENT '프로필 이미지 파일 ID',
    
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    CONSTRAINT `uk_users_username` UNIQUE(username),
    CONSTRAINT `uk_users_email` UNIQUE(email),
    CONSTRAINT `uk_users_nickname` UNIQUE(nickname),
    CONSTRAINT `chk_users_gender` CHECK(gender IN ('MALE', 'FEMALE', 'OTHER', 'NONE')),
    CONSTRAINT `fk_users_profile_file` FOREIGN KEY (profile_file_id) REFERENCES file_infos(id) ON DELETE SET NULL
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '사용자 기본 정보 테이블';

# === ROLES (권한) === #
CREATE TABLE roles (
	role_name VARCHAR(30) PRIMARY KEY,
    CONSTRAINT `chk_roles_role_name` CHECK(role_name IN ('ROLE_USER', 'ROLE_ADMIN', 'ROLE_MANAGER'))
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '사용자 권한 테이블';

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
    
# === BOARD_FILES (게시글 파일 매핑) === #
CREATE TABLE board_files (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    board_id BIGINT NOT NULL,
    file_id BIGINT NOT NULL,
    display_order INT DEFAULT 0,
    
    CONSTRAINT `fk_board_files_board` FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE,
    CONSTRAINT `fk_board_files_file_info` FOREIGN KEY (file_id) REFERENCES file_infos(id) ON DELETE CASCADE
)
	ENGINE=InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
    COMMENT = '게시글 파일 매핑 테이블';
    
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

SET FOREIGN_KEY_CHECKS = 1;