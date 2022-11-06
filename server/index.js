const express = require('express');
const { Pool, Client } = require('pg');
const app = express();

const credentials = {
    user: "postgres",
    host: "34.173.237.215",
    database: "events-data",
    password: "MZ{s.CxTb|JjvLBy"
}

async function test() {
    const pool = new pg.Pool(credentials)
    const now = await Pool.query("SELECT * from events;")
    await pool.end();
    return now;
}


app.get('/', (req, res) => {
  const name = process.env.NAME || 'World';
  res.send(`Hello ${name}!`);
});

app.get('/testGet', (req, res) => {
  res.send('HELP')
});

app.get('/test', (req, res) => {
    res.send(test())
});

// app.post('/location', (req, res) => {
//     res.
// });

const port = parseInt(process.env.PORT) || 8080;
app.listen(port, () => {
  console.log(`helloworld: listening on port ${port}`);
});