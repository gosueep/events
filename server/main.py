from google.cloud.sql.connector import Connector
import sqlalchemy
import pg8000
import os
from flask import Flask

app = Flask(__name__)
connector = Connector()

def getconn():
    conn = connector.connect(
        "hacknc22:us-central1:events-data",
        "pg8000",
        user="postgres",
        password="MZ{s.CxTb|JjvLBy",
        db="events-data"
    )
    return conn

pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)

# insert statement
insert_stmt = sqlalchemy.text(
    "INSERT INTO my_table (id, title) VALUES (:id, :title)",
)

with pool.connect() as db_conn:
    # insert into database
    # db_conn.execute(insert_stmt, id="book1", title="Book One")

    # query database
    result = db_conn.execute("SELECT * from events;").fetchall()

    # Do something with the results
    for row in result:
        print(row)


@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    return "Hello {}".format(getconn())

@app.route("/testGet")
def test_get():
    pool = sqlalchemy.create_engine(
        "postgresql+pg8000://",
        creator=getconn,
    )
    with pool.connect() as db_conn:
        result = db_conn.execute("SELECT * from events;").fetchall()
    return result

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))