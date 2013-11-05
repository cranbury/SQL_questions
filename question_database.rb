require 'singleton'
require 'sqlite3'

class QuestionDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end

  # def query(*args)
 #    result = QuestionDatabase.instance.execute(<<-SQL, *args)
 #      SELECT
 #        ?
 #      FROM
 #        ?
 #      WHERE
 #        ?.? = ?
 #    SQL
 #
 #    User.new(result.first)
 #  end
end


class User
  def self.all
    # execute a SELECT; result in an `Array` of `Hash`es, each
    # represents a single row.
    results = QuestionDatabase.instance.execute("SELECT * FROM users")
    results.map { |result| User.new(result) }
  end

  def self.find_by_id(id = self.id)
    result = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL

    User.new(result.first)
  end

  def self.find_by_name(fname,lname)
    results = QuestionDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      Where ? = fname AND ? = lname
    SQL

    results.map { |result| User.new(result) }
  end

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def authored_questions #return [] if no questions authored
   Question.find_by_author_id(self.id)
  end

  def authored_replies #refactor tp combine with above? #move to reply class?
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollower.followed_question_for_user(self.id)
  end

end



class Question
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM questions")
    results.map { |result| Question.new(result) }
  end

  def self.find_by_id(id = self.id)
    result = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id = ?
    SQL

    Question.new(result.first)
  end

  attr_accessor :id, :title, :body, :user_id

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @user_id = options["user_id"]
  end

  def self.find_by_author_id(id)
    results = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.user_id = ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def author
    result = QuestionDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        user_id
      FROM
        questions
      WHERE
        questions.id = ?
    SQL
    #p result
    #p result.first["user_id"].class
    User.find_by_id(result.first["user_id"])
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollower.followers_for_question(self.id)
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

end

class QuestionFollower
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM question_followers")
    results.map { |result| QuestionFollower.new(result) }
  end

  def self.find_by_id(id = self.id)
    result = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_followers
      WHERE
        question_followers.id = ?
    SQL

    QuestionFollower.new(result.first)
  end

  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id, @user_id, @question_id = options.values_at("id", "user_id", "question_id")
  end

  def self.followers_for_question(question_id = self.question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id AS id, fname, lname
      FROM
        question_followers
        JOIN users ON question_followers.user_id = users.id
      WHERE
        question_id = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.followed_question_for_user(user_id)
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id AS id, title, body, question_followers.user_id AS user_id
      FROM
        question_followers
        JOIN questions ON question_followers.question_id = questions.id
      WHERE
        question_followers.user_id = ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_followed_questions(n)
    results = QuestionDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.id AS id, title, body, questions.user_id AS user_id
    FROM questions
    LEFT JOIN (
        SELECT
          question_id, COUNT(id) as count
        FROM
          question_followers
        ) ON questions.id = question_id
    GROUP BY
      question_id
    ORDER BY
      count
    LIMIT
      ?

    SQL

     results.map { |result| Question.new(result) }
  end

end

class Reply
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM replies")
    results.map { |result| Reply.new(result) }
  end

  def self.find_by_id(id = self.id)
    result = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.id = ?
    SQL

    Reply.new(result.first)
  end

  attr_accessor :id, :user_id, :question_id, :parent_reply, :body

  def initialize(options = {})
    @id = options["id"]
    @user_id = options["user_id"]
    @question_id = options["question_id"]
    @body = options["body"]
    @parent_reply = options["parent_reply"]
  end

  def self.find_by_question_id(question_id = self.question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_user_id(user_id = self.user_id)
    results = QuestionDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.user_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def author
    result = QuestionDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        user_id
      FROM
        replies
      WHERE
        replies.id = ?
    SQL

    User.find_by_id(result.first["user_id"])
  end

  def question
    Question.find_by_id(self.question_id)
  end

  def find_parent_reply
    self.class.find_by_id(self.parent_reply)
  end

  def child_replies
    results = QuestionDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

end

class QuestionLike
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM question_likes")
    results.map { |result| QuestionLike.new(result) }
  end

  def self.find_by_id(id = self.id)
    result = QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_likes.id = ?
    SQL

    QuestionLike.new(result.first)
  end

  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id = options["id"]
    @user_id = options["user_id"]
    @question_id = options["question_id"]
  end

  def self.likers_for_question_id(question_id)
    results = QuestionDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id AS id, fname, lname
      FROM
        question_likes
        JOIN users ON question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL

    results.map { |result| User.new(result) }
  end


end


if $PROGRAM_NAME != __FILE__
  $abe = User.new("id" => 1, "fname" => "Abe", "lname" => "S")
  $granger = User.new("id" => 2, "fname" => "Granger", "lname" => "A")
  $abe_ques = $abe.authored_questions.first
  $granger_reply = $abe_ques.replies.first
  $awesome_reply = $granger_reply.child_replies.first
  $granger_follower = QuestionFollower.new("id" => 1, "user_id" => 2, "question_id" => 1)
end
