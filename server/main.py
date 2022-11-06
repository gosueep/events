from google.cloud.sql.connector.connector import Connector
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


# with pool.connect() as db_conn:

#     # query database
#     result = db_conn.execute('SELECT * from pg_catalog.pg_tables').fetchall()

#     # Do something with the results
#     for row in result:
#         print(row)


@app.route("/")
def hello_world():
   return ""

# make location table
@app.route("/location")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("INSERT INTO location (id, lat, long) VALUES (:id, :lat, :long)", id=d['device_id'], lat=d['lat'], long=d['long'])

app.route("/rsvp")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("UPDATE event SET attendees = attendees + 1 WHERE event_id = :event_id", event_id=d['event'])
        # todo - check if already in
        db_conn.execute("INSERT INTO rsvp (event_id, device_id) VALUES (:event_id, :device_id)", event_id=d['event'], device_id=d['device_id'])

# 
app.route("/events")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database                                                          sfasdfasdfasdf
        db_conn.execute("SELECT description, event_id, event_name, number_ppl, people FROM ...WHERE ", event_id=d['event'], device_id=d['device_id'])

# MAKE TABLE
app.route("/register")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("INSERT INTO user (event_id, device_id) VALUES (:event_id, :device_id)", event_id=d['event'], device_id=d['device_id'])

# MAKE TABLE
app.route("/startup")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("INSERT INTO device (device_id, manufacturer, model, device_version, version) VALUES (:device_id, :manufacturer, :model, :device_version, :version)", device_id=d['device_id'], manufacturer=d['manufacturer'], model=d['model'], device_version=d['device_version'], version=d['version'])

# RETURN GEN ID
app.route("/create_event")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute("INSERT INTO event (device_id, name, description, start_time, end_time) VALUES (:device_id, :name, :description, :start_time, :end_time)", device_id=d['device_id'], name=d['name'], description = d['description'], start_time=d['start_time'], end_time=d['end_time'])



if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))