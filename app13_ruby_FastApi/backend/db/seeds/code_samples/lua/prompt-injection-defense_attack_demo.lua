-- VULNERABLE — do not use in production
local prompt = "Answer using this document.\nDocument: " .. retrieved_doc .. "\nQuestion: " .. question
local res = llm_client.complete(prompt)
