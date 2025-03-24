from flask import Flask, render_template, jsonify
import random
import json

app = Flask(__name__)

# Load quotes from a JSON file
with open('quotes.json', 'r') as f:
    quotes = json.load(f)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/get_quote')
def get_quote():
    # Return a random quote as JSON
    quote = random.choice(quotes)
    return jsonify(quote)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)