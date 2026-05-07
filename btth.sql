CREATE DATABASE SocialNetworkDB;
USE SocialNetworkDB;


CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE posts (
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_posts_created_at
ON posts(created_at);

CREATE TABLE likes (
    like_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    FOREIGN KEY (post_id)
    REFERENCES posts(post_id)
    ON DELETE CASCADE
);


CREATE TABLE comments (
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    FOREIGN KEY (post_id)
    REFERENCES posts(post_id)
    ON DELETE CASCADE
);


CREATE TABLE friends (
    friend_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    friend_user_id INT NOT NULL,
    status ENUM('pending','accepted','blocked') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    FOREIGN KEY (friend_user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
);

-- =========================================
-- CHỨC NĂNG 1
-- VIEW HỒ SƠ NGƯỜI DÙNG AN TOÀN
-- =========================================

CREATE VIEW view_user_info AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users;

-- =========================================
-- CHỨC NĂNG 2
-- VIEW THỐNG KÊ TƯƠNG TÁC
-- =========================================

CREATE VIEW view_post_statistics AS
SELECT
    p.post_id,
    p.content,
    u.username,

    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments

FROM posts p

LEFT JOIN users u
ON p.user_id = u.user_id

LEFT JOIN likes l
ON p.post_id = l.post_id

LEFT JOIN comments c
ON p.post_id = c.post_id

WHERE p.is_deleted = FALSE

GROUP BY
    p.post_id,
    p.content,
    u.username;


INSERT INTO users(username,email,password)
VALUES
('alice','alice@gmail.com','123'),
('bob','bob@gmail.com','456'),
('charlie','charlie@gmail.com','789');


INSERT INTO posts(user_id,content)
VALUES
(1,'Hello everyone'),
(2,'My first post'),
(3,'Good morning');


INSERT INTO likes(user_id,post_id)
VALUES
(1,2),
(2,1),
(3,1);


INSERT INTO comments(user_id,post_id,comment_text)
VALUES
(1,2,'Great post'),
(2,1,'Nice'),
(3,1,'Amazing');


INSERT INTO friends(user_id,friend_user_id,status)
VALUES
(1,2,'accepted'),
(2,1,'accepted'),
(1,3,'accepted'),
(3,1,'accepted');


SELECT * FROM view_user_info;

SELECT * FROM view_post_statistics;

-- =========================================
-- CHỨC NĂNG 3
-- PROCEDURE ĐĂNG KÝ TÀI KHOẢN
-- =========================================

DROP PROCEDURE IF EXISTS sp_add_user;

DELIMITER //

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN

    DECLARE email_count INT;

    SELECT COUNT(*) INTO email_count
    FROM users
    WHERE email = p_email;

    IF email_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email da duoc su dung';

    ELSE

        INSERT INTO users(username,password,email)
        VALUES(p_username,p_password,p_email);

    END IF;

END //

DELIMITER ;


CALL sp_add_user(
    'david',
    '123456',
    'david@gmail.com'
);

-- =========================================
-- CHỨC NĂNG 4
-- PROCEDURE TẠO BÀI VIẾT
-- =========================================

DROP PROCEDURE IF EXISTS sp_create_post;

DELIMITER //

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN

    INSERT INTO posts(user_id,content)
    VALUES(p_user_id,p_content);

    SET p_new_post_id = LAST_INSERT_ID();

END //

DELIMITER ;

SET @new_post_id = 0;

CALL sp_create_post(
    1,
    'This is my new post',
    @new_post_id
);

SELECT @new_post_id;

-- =========================================
-- CHỨC NĂNG 5
-- PROCEDURE DANH SÁCH BẠN BÈ PHÂN TRANG
-- =========================================

DROP PROCEDURE IF EXISTS sp_get_friends;

DELIMITER //

CREATE PROCEDURE sp_get_friends(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN

    SELECT
        u.user_id,
        u.username,
        u.email,
        f.created_at

    FROM friends f

    JOIN users u
    ON f.friend_user_id = u.user_id

    WHERE f.user_id = p_user_id
    AND f.status = 'accepted'

    LIMIT p_limit OFFSET p_offset;

END //

DELIMITER ;


CALL sp_get_friends(1,5,0);
