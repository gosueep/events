from google.cloud.sql.connector.connector import Connector
import sqlalchemy
from sqlalchemy import text
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
        db="postgres"
    )
    return conn

pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)


@app.route("/")
def hello_world():
   return "Events API"

@app.post("/location")
def update_location():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute(text("INSERT INTO location (id, lat, long, pos) VALUES (:id, lat, long, point(:long, :lat)) ON CONFLICT id DO UPDATE SET id = :id"), id=d['device_id'], lat=d['lat'], long=d['long'])
        return 202

@app.post("/rsvp")
def rsvp():
    d = request.json 
    with pool.connect() as db_conn:
        # # insert into database
        # db_conn.execute(text("UPDATE event SET attendees = attendees + 1 WHERE event_id = :event_id"), event_id=d['event'])

        # if already in database / user already RSVP'd, do not add again 
        if db_conn.execute(text("COUNT(*) FROM rsvp WHERE event_id = :event_id AND device_id = :device_id")) < 1:
            db_conn.execute(text("INSERT INTO rsvp (event_id, device_id) VALUES (:event_id, :device_id)"), event_id=d['event'], device_id=d['device_id'])
        
        # return number of people rsvp'd
        output = {}
        output['num_ppl'] = db_conn.execute(text("COUNT(*) FROM rsvp WHERE event_id = :event_id"))
        return json.dumps(output)

# return json dict of people
@app.post("/events")
def get_events():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        event_info = db_conn.execute(text("SELECT description, event_id, event_name FROM event WHERE event_id = :event_id"), event_id=d['event'], device_id=d['device_id'])
        ppl_info = db_conn.execute(text("SELECT name, lat, long WHERE device_id IN (SELECT * FROM (location JOIN profile ON location.device_id = profile.device_id) WHERE (:event_point <@> pos) < :range"), event_point=d['event_point'], range=d['range'])
        output = {event_info} + {ppl_info}
        return json.dumps(output)


@app.post("/register")
def register_profile():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute(text("INSERT INTO profile (name, device_id) VALUES (:event_id, :device_id) ON CONFLICT device_id DO UPDATE SET name = excluded.name "), name=d['name'], device_id=d['device_id'])
        return 202

@app.post("/startup")
def init_device():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute(text("INSERT INTO device (id, manufacturer, model, device_version, version) VALUES (:device_id, :manufacturer, :model, :device_version, :version) ON CONFLICT id (manufacturer, model, device_version, version) = (excluded.manufacturer, excluded.model, excluded.device_version, excluded.version)"), device_id=d['device_id'], manufacturer=d['manufacturer'], model=d['model'], device_version=d['device_version'], version=d['version'])
        return 202

# RETURN GEN ID
@app.post("/create_event")
def create_event():
    d = request.json 
    with pool.connect() as db_conn:
        # insert into database
        db_conn.execute(text("INSERT INTO event (device_id, name, description, start_time, end_time) VALUES (:device_id, :name, :description, :start_time, :end_time)"), device_id=d['device_id'], name=d['name'], description = d['description'], start_time=d['start_time'], end_time=d['end_time'])
        # return db_conn.execute("SELECT event_id FROM event WHERE device_id = ")
        output = {}
        output['event_id'] = db_conn.execute(text("SELECT MAX(event_id) FROM event"))
        return json.dumps(output)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))