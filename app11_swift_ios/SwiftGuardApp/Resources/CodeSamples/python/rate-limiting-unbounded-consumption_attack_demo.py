# VULNERABLE — do not use in production
@app.route("/chat", methods=["POST"])
def chat():
    message = request.json["message"]
    return jsonify({"reply": llm.complete(message)})
