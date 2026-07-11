# VULNERABLE — do not use in production
def answer_with_context(question, retrieved_doc):
    prompt = f"System: Answer using this document.\nDocument: {retrieved_doc}\nQuestion: {question}"
    return llm.complete(prompt)
