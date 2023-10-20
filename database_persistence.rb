require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
    list = result.first
    todos = find_todos_for_list(id)
    {id: list["id"].to_i, name: list["name"], todos: todos}

  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
      todos = find_todos_for_list(tuple["id"])
      {id: tuple["id"], name: tuple["name"], todos: todos}
    end
  end

  def create_new_list(list_name)
    query("INSERT INTO lists (name) VALUES ($1)", list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE todos.list_id = $1", id)
    query("DELETE FROM lists WHERE lists.id = $1", id)
  end

  def update_list_name(id, new_name)
    query("UPDATE lists SET name = $1 WHERE id = $2", new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = True WHERE list_id = $1"
    query(sql, list_id)
  end

  private
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_todos_for_list(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todo_result = query(todo_sql, list_id)
    todo_result.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["completed"] == "t"}
    end
  end

end