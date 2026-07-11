# SECURE pattern
from flask_limiter import Limiter

limiter = Limiter(app, key_func=lambda: request.headers.get("X-User-Id"))

@app.route("/chat", methods=["POST"])
@limiter.limit("20 per minute")  # WHY: caps requests per user, bounding both compute cost and "denial of wallet" risk (LLM10:2025)
def chat():
    message = request.json["message"]
    return jsonify({"reply": llm.complete(message)})
