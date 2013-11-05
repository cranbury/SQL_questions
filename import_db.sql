CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
  );

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);


CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
  );

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  body VARCHAR(255) NOT NULL,
  parent_reply INTEGER,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
  );

/* ############################# */
INSERT INTO
  users (fname, lname)
VALUES
('Abe', 'S'),
('Granger', 'A');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('What?','is the meaning of life?', 1),
  ('Why?','...did they fine us?', 2);

INSERT INTO
  question_followers (user_id, question_id)
VALUES
(1, 1);

INSERT INTO
  replies (question_id, user_id, body, parent_reply)
VALUES
(1,(SELECT id FROM users WHERE fname = 'Granger'), 'Chocolate', null),
(1,(SELECT id FROM users WHERE fname = 'Abe'), 'Awesome!', 1);

INSERT INTO
  question_likes (question_id, user_id)
VALUES
(1,(SELECT id FROM users WHERE fname = 'Granger'));




