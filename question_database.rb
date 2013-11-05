require 'singleton'
require 'sqlite3'

class QuestionDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  def self.all
    # execute a SELECT; result in an `Array` of `Hash`es, each
    # represents a single row.
    results = QuestionDatabase.instance.execute("SELECT * FROM users")
    results.map { |result| User.new(result) }
  end
end

class Question
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM questions")
    results.map { |result| Question.new(result) }
  end
end

class QuestionFollower
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM question_followers")
    results.map { |result| QuestionFollower.new(result) }
  end
end

class Reply
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM replies")
    results.map { |result| Reply.new(result) }
  end
end

class QuestionLike
  def self.all
    results = QuestionDatabase.instance.execute("SELECT * FROM question_likes")
    results.map { |result| QuestionLike.new(result) }
  end
end
