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
    user_id INT,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
);

CREATE TABLE likes (
    like_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    post_id INT,
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
    user_id INT,
    post_id INT,
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
    user_id INT,
    friend_user_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE,

    FOREIGN KEY (friend_user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_posts_user
ON posts(user_id);

CREATE INDEX idx_likes_post
ON likes(post_id);

CREATE INDEX idx_comments_post
ON comments(post_id);

CREATE VIEW view_user_info AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users;

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

GROUP BY
    p.post_id,
    p.content,
    u.username;

INSERT INTO users(username, email, password)
VALUES
('alice', 'alice@gmail.com', '123'),
('bob', 'bob@gmail.com', '456');

INSERT INTO posts(user_id, content)
VALUES
(1, 'Hello World'),
(2, 'My first post');

INSERT INTO likes(user_id, post_id)
VALUES
(1, 2),
(2, 1);

INSERT INTO comments(user_id, post_id, comment_text)
VALUES
(1, 2, 'Great post'),
(2, 1, 'Nice');

INSERT INTO friends(user_id, friend_user_id)
VALUES
(1,2),
(2,1);

SELECT * FROM view_user_info;

SELECT * FROM view_post_statistics;

DROP PROCEDURE IF EXISTS sp_add_user;

DELIMITER //

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN

    DECLARE email_count INT;
    DECLARE user_count INT;

    SELECT COUNT(*) INTO email_count
    FROM users
    WHERE email = p_email;

    SELECT COUNT(*) INTO user_count
    FROM users
    WHERE username = p_username;

    IF email_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email da duoc su dung';

    ELSEIF user_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Username da ton tai';

    ELSE

        INSERT INTO users(username, password, email)
        VALUES(p_username, p_password, p_email);

    END IF;

END //

DELIMITER ;

CALL sp_add_user(
    'david',
    '123456',
    'david@gmail.com'
);

DROP PROCEDURE IF EXISTS sp_create_post;

DELIMITER //

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN

    INSERT INTO posts(user_id, content)
    VALUES(p_user_id, p_content);

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

DROP PROCEDURE IF EXISTS sp_get_friends_pagination;

DELIMITER //

CREATE PROCEDURE sp_get_friends_pagination(
    IN p_user_id INT,
    IN p_page INT,
    IN p_limit INT
)
BEGIN

    DECLARE v_offset INT;

    SET v_offset = (p_page - 1) * p_limit;

    SELECT
        u.user_id,
        u.username,
        u.email,
        f.created_at

    FROM friends f

    JOIN users u
    ON f.friend_user_id = u.user_id

    WHERE f.user_id = p_user_id

    LIMIT p_limit OFFSET v_offset;

END //

DELIMITER ;

CALL sp_get_friends_pagination(1,1,5);
