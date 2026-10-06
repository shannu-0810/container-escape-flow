from flask import Flask, request

app = Flask(__name__)

@app.route("/")
def index():
    return """
    <h1>Internal Service Portal</h1>
    <p>Welcome to the internal service portal.</p>
    <p>Environment: APP01</p>
    """

@app.route("/health")
def health():
    return {"status": "ok"}

@app.route("/echo")
def echo():
    message = request.args.get("message", "")
    return f"<h2>Message</h2><p>{message}</p>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
