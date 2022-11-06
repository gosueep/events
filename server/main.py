from google.cloud.sql.connector import Connector
import sqlalchemy
import requests, json
import os
from flask import Flask, request

app = Flask(__name__)
connector = Connector()

def getconn():
    conn = connector.connect(
        "hacknc22:us-central1:events-data",
        "pg8000",
        user="postgres",
        password="MZ{s.CxTb|JjvLBy",
        db="events_info"
    )
    return conn

pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)


with pool.connect() as db_conn:

    # query database
    result = db_conn.execute('SELECT * from pg_catalog.pg_tables').fetchall()

    # Do something with the results
    for row in result:
        print(row)


@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    return "Hello {}".format(getconn())

@app.route("/location")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("INSERT INTO devices (id, lat, long) VALUES (:id, :lat, :long)", id=d['device_id'], lat=d['lat'], long=d['long'])

app.route("/rsvp")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("UPDATE events SET attendees = attendees + 1 WHERE event_id = :event_id", event_id=d['event'])
        # todo - check if already in
        db_conn.execute("INSERT INTO rsvp (event_id, device_id) VALUES (:event_id, :device_id)", event_id=d['event'], device_id=d['device_id'])

app.route("/events")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("UPDATE events SET attendees = attendees + 1 WHERE event_id = :event_id", event_id=d['event'])
        # todo - check if already in
        db_conn.execute("INSERT INTO rsvp (event_id, device_id) VALUES (:event_id, :device_id)", event_id=d['event'], device_id=d['device_id'])



if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))