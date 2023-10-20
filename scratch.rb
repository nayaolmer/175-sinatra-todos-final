require "pg"
require "pry"

db = PG.connect(dbname: "todos")

sql = "SELECT * FROM lists;"
result = db.exec(sql)

result.map do |tuple|
  {id: tuple[0], name: tuple[1], todos: tuple[2]}
end

binding.pry

